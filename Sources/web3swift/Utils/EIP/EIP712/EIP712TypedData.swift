//
//  EIP721TypedData.swift
//  
//
//  Created by math on 2022/1/14.
//

import BigInt
import CryptoSwift
import Foundation

/*
 {
     "types": {
         "EIP712Domain": [{
             "name": "name",
             "type": "string"
         }, {
             "name": "version",
             "type": "string"
         }, {
             "name": "verifyingContract",
             "type": "address"
         }],
         "RelayRequest": [{
             "name": "target",
             "type": "address"
         }, {
             "name": "encodedFunction",
             "type": "bytes"
         }, {
             "name": "gasData",
             "type": "GasData"
         }, {
             "name": "relayData",
             "type": "RelayData"
         }],
         "GasData": [{
             "name": "gasLimit",
             "type": "uint256"
         }, {
             "name": "gasPrice",
             "type": "uint256"
         }, {
             "name": "pctRelayFee",
             "type": "uint256"
         }, {
             "name": "baseRelayFee",
             "type": "uint256"
         }],
         "RelayData": [{
             "name": "senderAddress",
             "type": "address"
         }, {
             "name": "senderNonce",
             "type": "uint256"
         }, {
             "name": "relayWorker",
             "type": "address"
         }, {
             "name": "paymaster",
             "type": "address"
         }]
     },
     "domain": {
         "name": "GSN Relayed Transaction",
         "version": "1",
         "chainId": 42,
         "verifyingContract": "0x6453D37248Ab2C16eBd1A8f782a2CBC65860E60B"
     },
     "primaryType": "RelayRequest",
     "message": {
         "target": "0x9cf40ef3d1622efe270fe6fe720585b4be4eeeff",
         "encodedFunction": "0xa9059cbb0000000000000000000000002e0d94754b348d208d64d52d78bcd443afa9fa520000000000000000000000000000000000000000000000000000000000000007",
         "gasData": {
             "gasLimit": "39507",
             "gasPrice": "1700000000",
             "pctRelayFee": "70",
             "baseRelayFee": "0"
         },
         "relayData": {
             "senderAddress": "0x22d491bde2303f2f43325b2108d26f1eaba1e32b",
             "senderNonce": "3",
             "relayWorker": "0x3baee457ad824c94bd3953183d725847d023a2cf",
             "paymaster": "0x957F270d45e9Ceca5c5af2b49f1b5dC1Abb0421c"
         }
     }
 }
 */

/// A struct represents EIP712 type tuple
public struct EIP712TypedDataType: Codable {
    public var name: String
    public var type: String
}

/// A struct represents EIP712 TypedData
public struct EIP712TypedData: Codable {
    public var types: [String: [EIP712TypedDataType]]
    public var primaryType: String
    public var domain: EIP712TypedData.JSON
    public var message: EIP712TypedData.JSON

}

public extension EIP712TypedData {
    /// Sign-able hash for an `EIP712TypedData`
    func digestData() throws -> Data {
        let data = Data([0x19, 0x01]) + (try self.hashStruct("EIP712Domain", json: domain)) + (try self.hashStruct(self.primaryType, json: message))
        return EIP712Crypto.keccak256(data)
    }
    
    private func dependencies(_ type: String, dependencies: [String] = []) -> [String] {
        let trailingType = type.dropTrailingSquareBrackets
        var found = dependencies
        guard !found.contains(trailingType), let primaryTypes = self.types[trailingType] else {
            return found
        }
        found.append(trailingType)
        for primaryType in primaryTypes {
            self.dependencies(primaryType.type, dependencies: found).forEach { found.append($0) }
        }
        return found
    }
    
    private func encodePrimaryType(_ type: String) -> String {
        guard let valueTypes = self.types[type] else { return type + "()" }
        
        let parametrs: [String] = valueTypes.compactMap { valueType in
            return valueType.type + " " + valueType.name
        }
        return type + "(" + parametrs.joined(separator: ",") + ")"
    }
    
    func encodeType(_ type: String) -> String {
        let dependencies = self.dependencies(type).map{ self.encodePrimaryType($0) }
        let selfPrimaryType = self.encodePrimaryType(type)
        
        let result = Set(dependencies).filter { $0 != selfPrimaryType }
        return selfPrimaryType + result.sorted().joined()
    }
    
    private func typehash(_ type: String) -> Data {
        return EIP712Crypto.keccak256(encodeType(type))
    }
    
    private func hashStruct(_ type: String, json: JSON) throws -> Data {
        let typeHash = self.typehash(type)
        let d = try encodeData(type, json: json)
        return EIP712Crypto.keccak256(typeHash + d)
    }
    
    private func encodeField(_ type: String, name: String, json: JSON) throws -> (ABI.Element.ParameterType, AnyObject) {
        var abiType: ABI.Element.ParameterType
        var abiValue: AnyObject
        switch type {
        case "bool":
            abiType = .bool
            abiValue = (json.boolValue ?? false) as AnyObject
        case _ where NSPredicate(format:"SELF MATCHES %@", "^int\\d{0,}$").evaluate(with: type):
            guard let v = json.stringValue else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            let bits = UInt64(type.replacingOccurrences(of: "int", with: "")) ?? UInt64(256)
            abiType = .int(bits: bits)
            abiValue = v as AnyObject
        case _ where NSPredicate(format:"SELF MATCHES %@", "^uint\\d{0,}$").evaluate(with: type):
            guard let v = json.stringValue else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            let bits = UInt64(type.replacingOccurrences(of: "uint", with: "")) ?? UInt64(256)
            abiType = .uint(bits: bits)
            abiValue = v as AnyObject
        case "address":
            guard let v = json.stringValue, let address = EthereumAddress(v) else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            abiType = .address
            abiValue = address as AnyObject
        case "bytes":
            guard let v = json.stringValue?.stripHexPrefix() else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            abiType = .bytes(length: 32)
            abiValue = EIP712Crypto.keccak256(Data(hex: v)) as AnyObject
        case _ where NSPredicate(format:"SELF MATCHES %@", "^bytes\\d{1,}$").evaluate(with: type):
            guard let v = json.stringValue?.stripHexPrefix() else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            let bits = UInt64(type.replacingOccurrences(of: "bytes", with: "")) ?? UInt64(32)
            abiType = .bytes(length: bits)
            abiValue = Data(hex: v) as AnyObject
        case "string":
            guard let v = json.stringValue?.data(using: .utf8) else {
                throw Web3Error.processingError(desc: "Not solidity type")
            }
            abiType = .bytes(length: 32)
            abiValue = EIP712Crypto.keccak256(v) as AnyObject
        default:
            switch json {
            case .object(_):
                abiType = .bytes(length: 32)
                abiValue = try self.hashStruct(type, json: json) as AnyObject
            case .array(let arr):
                let arrType = String(type[type.startIndex..<type.index(of: "[")!])
                var data = Data()
                for a in arr {
                    let (_t, _v) = try encodeField(arrType, name: name, json: a)
                    data +=  ABIEncoder.encodeSingleType(type: _t, value: _v) ?? Data()
                }
                abiType = .bytes(length: 32)
                abiValue = EIP712Crypto.keccak256(data) as AnyObject
            default:
                throw Web3Error.processingError(desc: "Not solidity type \(type)")
            }
        }
        return (abiType, abiValue)
    }
    
    private func encodeData(_ type: String, json: JSON) throws -> Data {
        let valueTypes = self.types[type] ?? []
        var parametrs: [Data] = []
        for valueType in valueTypes {
            guard let field = json[valueType.name] else {
                continue
            }
            let (abiType, abiValue) = try encodeField(valueType.type, name: valueType.name, json: field)
            guard let result = ABIEncoder.encodeSingleType(type: abiType, value: abiValue) else {
                throw Web3Error.processingError(desc: "ABI encode error")
            }
            parametrs.append(result)
        }
        let encoded = parametrs.flatMap { $0.bytes }
        return Data(encoded)
    }
}

/// A JSON value representation. This is a bit more useful than the naïve `[String:Any]` type
/// for JSON values, since it makes sure only valid JSON values are present & supports `Equatable`
/// and `Codable`, so that you can compare values for equality and code and decode them into data
/// or strings.
public extension EIP712TypedData {
    enum JSON: Equatable {
        case string(String)
        case number(Int64)
        case object([String: EIP712TypedData.JSON])
        case array([EIP712TypedData.JSON])
        case bool(Bool)
        case null
    }
}
extension EIP712TypedData.JSON: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let object = try? container.decode([String: EIP712TypedData.JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([EIP712TypedData.JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Int64.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

extension EIP712TypedData.JSON: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}

extension EIP712TypedData.JSON {
    /// Return the string value if this is a `.string`, otherwise `nil`
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        if case .number(let value) = self {
            return String(value)
        }
        return nil
    }
    
    /// Return the bool value if this is a `.bool`, otherwise `nil`
    var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    /// If this is an `.array`, return item at index
    ///
    /// If this is not an `.array` or the index is out of bounds, returns `nil`.
    subscript(index: Int) -> EIP712TypedData.JSON? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    /// If this is an `.object`, return item at key
    subscript(key: String) -> EIP712TypedData.JSON? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }
}

fileprivate extension String {
    var dropTrailingSquareBrackets: String {
        if let i = index(of: "["), hasSuffix("]") {
            return String(self[startIndex..<i])
        } else {
            return self
        }
    }
}
