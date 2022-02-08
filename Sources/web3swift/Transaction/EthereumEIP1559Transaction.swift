//
//  EthereumEIP1559Transaction.swift
//  
//
//  Created by math on 2022/2/8.
//

import Foundation
import BigInt
import Secp256k1Swift

public struct EthereumEIP1559Transaction: CustomStringConvertible {
    private var type: UInt8 = 0x02
    public var nonce: BigUInt
    public var maxPriorityFeePerGas: BigUInt = BigUInt(0)
    public var maxFeePerGas: BigUInt = BigUInt(0)
    public var gasLimit: BigUInt = BigUInt(0)
    // The destination address of the message, left undefined for a contract-creation transaction.
    public var to: EthereumAddress
    public var value: BigUInt?
    public var data: Data
    public var v: BigUInt = BigUInt(1)
    public var r: BigUInt = BigUInt(0)
    public var s: BigUInt = BigUInt(0)
    public var chainID: BigUInt = BigUInt(0)
    
    public var accessList: Array<AnyObject> = []

    public var hash: Data? {
        guard let encoded = self.encode(forSignature: false) else {return nil}
        let hash = encoded.sha3(.keccak256)
        return hash
    }
    
    public init(maxPriorityFeePerGas: BigUInt, maxFeePerGas: BigUInt, gasLimit: BigUInt, to: EthereumAddress, value: BigUInt, data: Data, chainID: BigUInt) {
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
            toReturn = toReturn + "Type: " + String(self.type) + "\n"
            toReturn = toReturn + "Nonce: " + String(self.nonce) + "\n"
            toReturn = toReturn + "MaxPriorityFeePerGas: " + String(self.maxPriorityFeePerGas) + "\n"
            toReturn = toReturn + "maxFeePerGas: " + String(self.maxFeePerGas) + "\n"
            toReturn = toReturn + "Gas limit: " + String(self.gasLimit) + "\n"
            toReturn = toReturn + "To: " + self.to.address + "\n"
            toReturn = toReturn + "Value: " + String(self.value ?? "nil") + "\n"
            toReturn = toReturn + "Data: " + self.data.toHexString().addHexPrefix().lowercased() + "\n"
            toReturn = toReturn + "v: " + String(self.v) + "\n"
            toReturn = toReturn + "r: " + String(self.r, radix: 16) + "\n"
            toReturn = toReturn + "s: " + String(self.s, radix: 16) + "\n"
            toReturn = toReturn + "chainID: " + String(self.chainID) + "\n"
            toReturn = toReturn + "sender: " + String(describing: self.sender?.address)  + "\n"
            toReturn = toReturn + "hash: " + String(describing: self.hash?.toHexString().addHexPrefix()) + "\n"
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
        guard let vData = v.serialize().setLengthLeft(1) else {return nil}
        guard let rData = r.serialize().setLengthLeft(32) else {return nil}
        guard let sData = s.serialize().setLengthLeft(32) else {return nil}
        guard let signatureData = SECP256K1.marshalSignature(v: vData, r: rData, s: sData) else {return nil}
        guard let hash = self.hashForSignature() else {return nil}
        guard let publicKey = SECP256K1.recoverPublicKey(hash: hash, signature: signatureData) else {return nil}
        return publicKey
    }
    
    public func encode(forSignature:Bool = false) -> Data? {
        if (forSignature) {
            let fields = [self.chainID, self.nonce, self.maxPriorityFeePerGas, self.maxFeePerGas, self.gasLimit, self.to.addressData, self.value!, self.data, self.accessList] as [AnyObject]
            guard let encode = RLP.encode(fields) else { return nil }
            return Data([self.type]) + encode
        } else {
            let fields = [self.chainID, self.nonce, self.maxPriorityFeePerGas, self.maxFeePerGas, self.gasLimit, self.to.addressData, self.value!, self.data, self.accessList, self.v, self.r, self.s] as [AnyObject]
            guard let encode = RLP.encode(fields) else { return nil }
            return Data([self.type]) + encode
        }
    }
    
    public func hashForSignature() -> Data? {
        guard let encoded = self.encode(forSignature: true) else {return nil}
        let hash = encoded.sha3(.keccak256)
        return hash
    }
    
    public static func fromRaw(_ raw: Data) -> EthereumEIP1559Transaction? {
        guard raw.count > 0, raw.prefix(1) == Data([0x02]) else {return nil}
        guard let totalItem = RLP.decode(raw.subdata(in: 1 ..< raw.count)) else {return nil}
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
            return EthereumEIP1559Transaction(nonce: nonce, maxPriorityFeePerGas: maxPriorityFeePerGas, maxFeePerGas: maxFeePerGas, gasLimit: gasLimit, to: to, value: value, data: transactionData, chainID: chainID, v: v, r: r, s: s)
        case 9?:
            return nil
        default:
            return nil
        }
    }
}
