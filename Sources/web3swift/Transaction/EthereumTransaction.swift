//  web3swift
//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import BigInt
import Secp256k1Swift

public enum EthereumTransactionType: UInt8 {
    case Legacy = 0x00
    case EIP1559 = 0x02
}

public struct EthereumTransaction: CustomStringConvertible {
    public var type: EthereumTransactionType = .Legacy
    
    public var nonce: BigUInt
    
    // Legacy
    public var gasPrice: BigUInt = BigUInt(0)
    public var gasLimit: BigUInt = BigUInt(0)
    
    // EIP-1559
    public var maxPriorityFeePerGas: BigUInt = BigUInt(0)
    public var maxFeePerGas: BigUInt = BigUInt(0)
    public var accessList: Array<AnyObject> = []
    
    // The destination address of the message, left undefined for a contract-creation transaction.
    public var to: EthereumAddress
    // (optional) The value transferred for the transaction in wei, also the endowment if it’s a contract-creation transaction.
    // TODO - split EthereumTransaction to two classes: with optional and required value property, depends on type of transaction
    public var value: BigUInt?
    public var data: Data
    public var v: BigUInt = BigUInt(1)
    public var r: BigUInt = BigUInt(0)
    public var s: BigUInt = BigUInt(0)
    var chainID: BigUInt? = nil
    
    public var inferedChainID: BigUInt? {
        get{
            switch self.type {
            case .Legacy:
                if (self.r == BigUInt(0) && self.s == BigUInt(0)) {
                    return self.v
                } else if (self.v == BigUInt(27) || self.v == BigUInt(28)) {
                    return nil
                } else {
                    return ((self.v - BigUInt(1)) / BigUInt(2)) - BigUInt(17)
                }
            case .EIP1559:
                return self.chainID
            }
        }
    }
    
    public var intrinsicChainID: BigUInt? {
        get{
            return self.chainID
        }
    }
    
    public mutating func UNSAFE_setChainID(_ chainID: BigUInt?) {
        self.chainID = chainID
    }
    
    public var hash: Data? {
        var encoded: Data
        switch self.type {
        case .Legacy:
            let inferedChainID = self.inferedChainID
            if inferedChainID != nil {
                guard let enc = self.encode(forSignature: false, chainID: inferedChainID) else {return nil}
                encoded = enc
            } else {
                guard let enc = self.encode(forSignature: false, chainID: self.chainID) else {return nil}
                encoded = enc
            }
        case .EIP1559:
            guard let enc = self.encode(forSignature: false) else {return nil}
            encoded = enc
        }
        let hash = encoded.sha3(.keccak256)
        return hash
    }
    
    public init(gasPrice: BigUInt, gasLimit: BigUInt, to: EthereumAddress, value: BigUInt, data: Data) {
        self.type = .Legacy
        self.nonce = BigUInt(0)
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.value = value
        self.data = data
        self.to = to
    }
    
    
    public init (nonce: BigUInt, gasPrice: BigUInt, gasLimit: BigUInt, to: EthereumAddress, value: BigUInt, data: Data, v: BigUInt, r: BigUInt, s: BigUInt) {
        self.type = .Legacy
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.v = v
        self.r = r
        self.s = s
    }
    
    public init(maxPriorityFeePerGas: BigUInt, maxFeePerGas: BigUInt, gasLimit: BigUInt, to: EthereumAddress, value: BigUInt, data: Data, chainID: BigUInt) {
        self.type = .EIP1559
        self.nonce = BigUInt(0)
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.maxFeePerGas = maxFeePerGas
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.chainID = chainID
    }
    
    public init(nonce: BigUInt, maxPriorityFeePerGas: BigUInt, maxFeePerGas: BigUInt, gasLimit: BigUInt, to: EthereumAddress, value: BigUInt, data: Data, chainID: BigUInt, v: BigUInt, r: BigUInt, s: BigUInt) {
        self.type = .EIP1559
        self.nonce = nonce
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.maxFeePerGas = maxFeePerGas
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.chainID = chainID
        self.v = v
        self.r = r
        self.s = s
    }
    
    public var description: String {
        get {
            var toReturn = ""
            toReturn = toReturn + "Transaction" + "\n"
            toReturn = toReturn + "Type: \(self.type)\n"
            toReturn = toReturn + "Nonce: " + String(self.nonce) + "\n"
            
            switch self.type {
            case .Legacy:
                toReturn = toReturn + "Gas price: " + String(self.gasPrice) + "\n"
                toReturn = toReturn + "Gas limit: " + String(describing: self.gasLimit) + "\n"
            case .EIP1559:
                toReturn = toReturn + "MaxPriorityFeePerGas: " + String(self.maxPriorityFeePerGas) + "\n"
                toReturn = toReturn + "maxFeePerGas: " + String(self.maxFeePerGas) + "\n"
            }
            
            toReturn = toReturn + "To: " + self.to.address + "\n"
            toReturn = toReturn + "Value: " + String(self.value ?? "nil") + "\n"
            toReturn = toReturn + "Data: " + self.data.toHexString().addHexPrefix().lowercased() + "\n"
            toReturn = toReturn + "v: " + String(self.v) + "\n"
            toReturn = toReturn + "r: " + String(self.r) + "\n"
            toReturn = toReturn + "s: " + String(self.s) + "\n"
            toReturn = toReturn + "Intrinsic chainID: " + String(describing:self.chainID) + "\n"
            toReturn = toReturn + "Infered chainID: " + String(describing:self.inferedChainID) + "\n"
            toReturn = toReturn + "sender: " + String(describing: self.sender?.address)  + "\n"
            toReturn = toReturn + "txid: \(self.txid)\n"
            return toReturn
        }
        
    }
    
    public var sender: EthereumAddress? {
        get {
            guard let publicKey = self.recoverPublicKey() else {return nil}
            return Web3.Utils.publicToAddress(publicKey)
        }
    }
    
    public func recoverPublicKey() -> Data? {
        if (self.r == BigUInt(0) && self.s == BigUInt(0)) {
            return nil
        }
        switch self.type {
        case .Legacy:
            var normalizedV: BigUInt = BigUInt(27)
            
            let inferedChainID = self.inferedChainID
            var d = BigUInt(0)
            if self.v >= 35 && self.v <= 38 {
                d = BigUInt(35)
            } else if self.v >= 31 && self.v <= 34 {
                d = BigUInt(31)
            } else if self.v >= 27 && self.v <= 30 {
                d = BigUInt(27)
            }
            if (self.chainID != nil && self.chainID != BigUInt(0)) {
                normalizedV = self.v - d - self.chainID! - self.chainID!
            } else if (inferedChainID != nil) {
                normalizedV = self.v - d - inferedChainID! - inferedChainID!
            } else {
                normalizedV = self.v - d
            }
            
            guard let vData = normalizedV.serialize().setLengthLeft(1) else {return nil}
            guard let rData = r.serialize().setLengthLeft(32) else {return nil}
            guard let sData = s.serialize().setLengthLeft(32) else {return nil}
            guard let signatureData = SECP256K1.marshalSignature(v: vData, r: rData, s: sData) else {return nil}
            var hash: Data
            if inferedChainID != nil {
                guard let h = self.hashForSignature(chainID: inferedChainID) else {return nil}
                hash = h
            } else {
                guard let h = self.hashForSignature(chainID: self.chainID) else {return nil}
                hash = h
            }
            guard let publicKey = SECP256K1.recoverPublicKey(hash: hash, signature: signatureData) else {return nil}
            return publicKey
        case .EIP1559:
            guard let vData = v.serialize().setLengthLeft(1) else {return nil}
            guard let rData = r.serialize().setLengthLeft(32) else {return nil}
            guard let sData = s.serialize().setLengthLeft(32) else {return nil}
            guard let signatureData = SECP256K1.marshalSignature(v: vData, r: rData, s: sData) else {return nil}
            guard let hash = self.hashForSignature(chainID: self.chainID) else {return nil}
            guard let publicKey = SECP256K1.recoverPublicKey(hash: hash, signature: signatureData) else {return nil}
            return publicKey
        }
    }
    
    public var txhash: String? {
        get{
            guard self.sender != nil else {return nil}
            guard let hash = self.hash else {return nil}
            let txid = hash.toHexString().addHexPrefix().lowercased()
            return txid
        }
    }
    
    public var txid: String? {
        get {
            return self.txhash
        }
    }
    
    public func encode(forSignature:Bool = false, chainID: BigUInt? = nil) -> Data? {
        switch self.type {
        case .Legacy:
            if (forSignature) {
                if chainID != nil  {
                    let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value!, self.data, chainID!, BigUInt(0), BigUInt(0)] as [AnyObject]
                    return RLP.encode(fields)
                }
                else if self.chainID != nil  {
                    let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value!, self.data, self.chainID!, BigUInt(0), BigUInt(0)] as [AnyObject]
                    return RLP.encode(fields)
                } else {
                    let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value!, self.data] as [AnyObject]
                    return RLP.encode(fields)
                }
            } else {
                let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value!, self.data, self.v, self.r, self.s] as [AnyObject]
                return RLP.encode(fields)
            }
        case .EIP1559:
            guard chainID != nil || self.chainID != nil else {
                return nil
            }
            let _chainID = chainID ?? self.chainID
            if (forSignature) {
                let fields = [_chainID!, self.nonce, self.maxPriorityFeePerGas, self.maxFeePerGas, self.gasLimit, self.to.addressData, self.value!, self.data, self.accessList] as [AnyObject]
                guard let encode = RLP.encode(fields) else { return nil }
                return Data([EthereumTransactionType.EIP1559.rawValue]) + encode
            } else {
                let fields = [_chainID!, self.nonce, self.maxPriorityFeePerGas, self.maxFeePerGas, self.gasLimit, self.to.addressData, self.value!, self.data, self.accessList, self.v, self.r, self.s] as [AnyObject]
                guard let encode = RLP.encode(fields) else { return nil }
                return Data([EthereumTransactionType.EIP1559.rawValue]) + encode
            }
        }
    }
    
    public func encodeAsDictionary(from: EthereumAddress? = nil) -> TransactionParameters? {
        var toString: String? = nil
        switch self.to.type {
        case .normal:
            toString = self.to.address.lowercased()
        case .contractDeployment:
            break
        }
        var params = TransactionParameters(from: from?.address.lowercased(),
                                           to: toString)
        let gasEncoding = self.gasLimit.abiEncode(bits: 256)
        params.gas = gasEncoding?.toHexString().addHexPrefix().stripLeadingZeroes()
        
        switch self.type {
        case .Legacy:
            let gasPriceEncoding = self.gasPrice.abiEncode(bits: 256)
            
            params.gasPrice = gasPriceEncoding?.toHexString().addHexPrefix().stripLeadingZeroes()
            params.maxFeePerGas = nil
            params.maxPriorityFeePerGas = nil
        case .EIP1559:
            let maxFeePerGasEncoding = self.maxFeePerGas.abiEncode(bits: 256)
            let maxPriorityFeePerGasEncoding = self.maxPriorityFeePerGas.abiEncode(bits: 256)
            
            params.maxFeePerGas = maxFeePerGasEncoding?.toHexString().addHexPrefix().stripLeadingZeroes()
            params.maxPriorityFeePerGas = maxPriorityFeePerGasEncoding?.toHexString().addHexPrefix().stripLeadingZeroes()
            params.gasPrice = nil
        }
        
        let valueEncoding = self.value?.abiEncode(bits: 256)
        params.value = valueEncoding?.toHexString().addHexPrefix().stripLeadingZeroes()
        if (self.data != Data()) {
            params.data = self.data.toHexString().addHexPrefix()
        } else {
            params.data = "0x"
        }
        return params
    }
    
    public func hashForSignature(chainID: BigUInt? = nil) -> Data? {
        guard let encoded = self.encode(forSignature: true, chainID: chainID) else {return nil}
        let hash = encoded.sha3(.keccak256)
        return hash
    }
    
    public static func fromRaw(_ raw: Data) -> EthereumTransaction? {
        var type: EthereumTransactionType = .Legacy
        if raw.count > 0, raw.prefix(1) == Data([EthereumTransactionType.EIP1559.rawValue]) {
            type = .EIP1559
        }
        guard let totalItem = RLP.decode(type == .EIP1559 ? raw.subdata(in: 1 ..< raw.count) : raw) else {return nil}
        guard let rlpItem = totalItem[0] else {return nil}
        switch rlpItem.count {
        case 12?:
            guard let chainIdData = rlpItem[0]!.data else {return nil}
            let chainID = BigUInt(chainIdData)
            guard let nonceData = rlpItem[1]!.data else {return nil}
            let nonce = BigUInt(nonceData)
            guard let maxPriorityFeePerGasData = rlpItem[2]!.data else {return nil}
            let maxPriorityFeePerGas = BigUInt(maxPriorityFeePerGasData)
            guard let maxFeePerGasData = rlpItem[3]!.data else {return nil}
            let maxFeePerGas = BigUInt(maxFeePerGasData)
            guard let gasLimitData = rlpItem[4]!.data else {return nil}
            let gasLimit = BigUInt(gasLimitData)
            var to:EthereumAddress
            switch rlpItem[5]!.content {
            case .noItem:
                to = EthereumAddress.contractDeploymentAddress()
            case .data(let addressData):
                if addressData.count == 0 {
                    to = EthereumAddress.contractDeploymentAddress()
                } else if addressData.count == 20 {
                    guard let addr = EthereumAddress(addressData) else {return nil}
                    to = addr
                } else {
                    return nil
                }
            case .list(_, _, _):
                return nil
            }
            guard let valueData = rlpItem[6]!.data else {return nil}
            let value = BigUInt(valueData)
            guard let transactionData = rlpItem[7]!.data else {return nil}
            guard let vData = rlpItem[9]!.data else {return nil}
            let v = BigUInt(vData)
            guard let rData = rlpItem[10]!.data else {return nil}
            let r = BigUInt(rData)
            guard let sData = rlpItem[11]!.data else {return nil}
            let s = BigUInt(sData)
            return EthereumTransaction(nonce: nonce, maxPriorityFeePerGas: maxPriorityFeePerGas, maxFeePerGas: maxFeePerGas, gasLimit: gasLimit, to: to, value: value, data: transactionData, chainID: chainID, v: v, r: r, s: s)
        case 9?:
            guard let nonceData = rlpItem[0]!.data else {return nil}
            let nonce = BigUInt(nonceData)
            guard let gasPriceData = rlpItem[1]!.data else {return nil}
            let gasPrice = BigUInt(gasPriceData)
            guard let gasLimitData = rlpItem[2]!.data else {return nil}
            let gasLimit = BigUInt(gasLimitData)
            var to:EthereumAddress
            switch rlpItem[3]!.content {
            case .noItem:
                to = EthereumAddress.contractDeploymentAddress()
            case .data(let addressData):
                if addressData.count == 0 {
                    to = EthereumAddress.contractDeploymentAddress()
                } else if addressData.count == 20 {
                    guard let addr = EthereumAddress(addressData) else {return nil}
                    to = addr
                } else {
                    return nil
                }
            case .list(_, _, _):
                return nil
            }
            guard let valueData = rlpItem[4]!.data else {return nil}
            let value = BigUInt(valueData)
            guard let transactionData = rlpItem[5]!.data else {return nil}
            guard let vData = rlpItem[6]!.data else {return nil}
            let v = BigUInt(vData)
            guard let rData = rlpItem[7]!.data else {return nil}
            let r = BigUInt(rData)
            guard let sData = rlpItem[8]!.data else {return nil}
            let s = BigUInt(sData)
            return EthereumTransaction.init(nonce: nonce, gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: transactionData, v: v, r: r, s: s)
        case 6?:
            return nil
        default:
            return nil
        }
    }
    
    static func createRequest(method: JSONRPCmethod, transaction: EthereumTransaction, transactionOptions: TransactionOptions?) -> JSONRPCrequest? {
        let onBlock = transactionOptions?.callOnBlock?.stringValue
        var request = JSONRPCrequest()
        request.method = method
        let from = transactionOptions?.from
        guard var txParams = transaction.encodeAsDictionary(from: from) else {return nil}
        if method == .estimateGas || transactionOptions?.gasLimit == nil {
            txParams.gas = nil
        }
        if method == .estimateGas || transactionOptions?.gasPrice == nil {
            txParams.gasPrice = nil
        }
        if method == .estimateGas || transactionOptions?.maxFeePerGas == nil {
            txParams.maxFeePerGas = nil
        }
        if method == .estimateGas || transactionOptions?.maxPriorityFeePerGas == nil {
            txParams.maxPriorityFeePerGas = nil
        }
        var params = [txParams] as Array<Encodable>
        if method.requiredNumOfParameters == 2 && onBlock != nil {
            params.append(onBlock as Encodable)
        }
        let pars = JSONRPCparams(params: params)
        request.params = pars
        if !request.isValid {return nil}
        return request
    }
    
    static func createRawTransaction(transaction: EthereumTransaction) -> JSONRPCrequest? {
        guard transaction.sender != nil else {return nil}
        guard let encodedData = transaction.encode() else {return nil}
        let hex = encodedData.toHexString().addHexPrefix().lowercased()
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.sendRawTransaction
        let params = [hex] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        if !request.isValid {return nil}
        return request
    }
}

public extension EthereumTransaction {
    init(type: EthereumTransactionType, to: EthereumAddress, data: Data, options: TransactionOptions) {
        let defaults = TransactionOptions.defaultOptions
        let merged = defaults.merge(options)
        self.nonce = BigUInt(0)
        self.type = type
        
        if let gP = merged.gasPrice {
            switch gP {
            case .manual(let value):
                self.gasPrice = value
            default:
                self.gasPrice = BigUInt("5000000000")
            }
        }
        
        if let mF = merged.maxFeePerGas {
            switch mF {
            case .manual(let value):
                self.maxFeePerGas = value
            default:
                self.maxFeePerGas = BigUInt("5000000000")
            }
        }
        
        if let mP = merged.maxPriorityFeePerGas {
            switch mP {
            case .manual(let value):
                self.maxPriorityFeePerGas = value
            default:
                self.maxPriorityFeePerGas = BigUInt("1000000000")
            }
        }
        
        if let gL = merged.gasLimit {
            switch gL {
            case .manual(let value):
                self.gasLimit = value
            default:
                self.gasLimit = BigUInt(UInt64(21000))
            }
        }

        if let value = merged.value {
            self.value = value
        }

        self.to = to
        self.data = data
    }
    
    func mergedWithOptions(_ options: TransactionOptions) -> EthereumTransaction {
        var tx = self;
        
        switch tx.type {
        case .Legacy:
            if let gP = options.gasPrice {
                switch gP {
                case .manual(let value):
                    tx.gasPrice = value
                default:
                    tx.gasPrice = BigUInt("5000000000")
                }
            }
        case .EIP1559:
            if let mF = options.maxFeePerGas {
                switch mF {
                case .manual(let value):
                    tx.maxFeePerGas = value
                default:
                    tx.maxFeePerGas = BigUInt("5000000000")
                }
            }
            
            if let mP = options.maxPriorityFeePerGas {
                switch mP {
                case .manual(let value):
                    tx.maxPriorityFeePerGas = value
                default:
                    tx.maxPriorityFeePerGas = BigUInt("1000000000")
                }
            }
        }
        
        if let gL = options.gasLimit {
            switch gL {
            case .manual(let value):
                tx.gasLimit = value
            case .limited(let value):
                tx.gasLimit = value
            default:
                tx.gasLimit = BigUInt(UInt64(21000))
            }
        }
        
        if options.value != nil {
            tx.value = options.value!
        }
        if options.to != nil {
            tx.to = options.to!
        }
        return tx
    }
    
    static func fromJSON(_ json: [String: Any], assignType: EthereumTransactionType? = nil) -> EthereumTransaction? {
        guard let options = TransactionOptions.fromJSON(json) else {return nil}
        guard let toString = json["to"] as? String else {return nil}
        let type: EthereumTransactionType = (json["maxFeePerGas"] != nil || json["maxPriorityFeePerGas"] != nil) ? .EIP1559 : .Legacy
        var to: EthereumAddress
        if toString == "0x" || toString == "0x0" {
            to = EthereumAddress.contractDeploymentAddress()
        } else {
            guard let ethAddr = EthereumAddress(toString) else {return nil}
            to = ethAddr
        }
        var dataString = json["data"] as? String
        if (dataString == nil) {
            dataString = json["input"] as? String
        }
        guard dataString != nil, let data = Data.fromHex(dataString!) else {return nil}
        var transaction = EthereumTransaction(type: assignType ?? type, to: to, data: data, options: options)
        if let nonceString = json["nonce"] as? String {
            guard let nonce = BigUInt(nonceString.stripHexPrefix(), radix: 16) else {return nil}
            transaction.nonce = nonce
        }
        if let vString = json["v"] as? String {
            guard let v = BigUInt(vString.stripHexPrefix(), radix: 16) else {return nil}
            transaction.v = v
        }
        if let rString = json["r"] as? String {
            guard let r = BigUInt(rString.stripHexPrefix(), radix: 16) else {return nil}
            transaction.r = r
        }
        if let sString = json["s"] as? String {
            guard let s = BigUInt(sString.stripHexPrefix(), radix: 16) else {return nil}
            transaction.s = s
        }
        if let valueString = json["value"] as? String {
            guard let value = BigUInt(valueString.stripHexPrefix(), radix: 16) else {return nil}
            transaction.value = value
        }
        let inferedChainID = transaction.inferedChainID
        if (transaction.inferedChainID != nil && transaction.v >= BigUInt(37)) {
            transaction.chainID = inferedChainID
        }
        return transaction
    }
    
}
