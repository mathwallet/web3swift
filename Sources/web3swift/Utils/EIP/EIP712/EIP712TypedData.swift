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
         "Vote": [{
             "name": "from",
             "type": "address"
         }, {
             "name": "space",
             "type": "string"
         }, {
             "name": "timestamp",
             "type": "uint64"
         }, {
             "name": "proposal",
             "type": "bytes32"
         }, {
             "name": "choice",
             "type": "uint32"
         }, {
             "name": "metadata",
             "type": "string"
         }],
         "EIP712Domain": [{
             "name": "name",
             "type": "string"
         }, {
             "name": "version",
             "type": "string"
         }]
     },
     "domain": {
         "name": "snapshot",
         "version": "0.1.4"
     },
     "primaryType": "Vote",
     "message": {
         "from": "0x306bb8081c7dd356ea951795ce4072e6e4bfdc32",
         "space": "pancake",
         "timestamp": "1642060678",
         "proposal": "0x08706912b77cef36d6da1ba408a11590a8a8fb79b50d4b9212599e13947fedb1",
         "choice": "1",
         "metadata": "{}"
     }
 }
    //hash -> 0x40122d8c04cce1df24d222717b8d7d1cb3537c79fa1a83790659df8e29becc27
 */

/// A struct represents EIP712 type tuple
public struct EIP712TypedDataType: Codable {
    var name: String
    var type: String
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
    var digest: Data {
        let data = Data([0x19, 0x01]) + (try! self.hash("EIP712Domain", json: domain)) + (try! self.hash(self.primaryType, json: message))
        return EIP712Crypto.keccak256(data)
    }
    
    private func dependencies() -> [String] {
        return []
    }
    
    func encodePrimaryType(_ type: String) -> String {
        guard let valueTypes = self.types[type] else { return type + "()" }
        
        let parametrs: [String] = valueTypes.compactMap { valueType in
            return valueType.type + " " + valueType.name
        }
        return type + "(" + parametrs.joined(separator: ",") + ")"
    }
    
    private func encodeType(_ type: String) -> String {
        let dependencies = self.dependencies()
        let selfPrimaryType = self.encodePrimaryType(type)
        debugPrint(selfPrimaryType)
        
        let result = Set(dependencies).filter { $0 != selfPrimaryType }
        return selfPrimaryType + result.sorted().joined()
    }
    
    private func typehash(_ type: String) -> Data {
        return EIP712Crypto.keccak256(encodeType(type))
    }
    
    private func hash(_ type: String, json: JSON) throws -> Data {
        typealias SolidityValue = (value: Any, type: ABI.Element.ParameterType)
        let valueTypes = self.types[type] ?? []
        var parametrs: [Data] = [self.typehash(type)]
        for valueType in valueTypes {
            let field = json[valueType.name]!
            let abiType: ABI.Element.ParameterType
            let abiValue: AnyObject
            switch valueType.type {
            case "bool":
                abiType = .bool
                abiValue = (field.boolValue ?? false) as AnyObject
            case "int8":
                guard let v = field.stringValue else { continue }
                abiType = .int(bits: 8)
                abiValue = v as AnyObject
            case "int16":
                guard let v = field.stringValue else { continue }
                abiType = .int(bits: 16)
                abiValue = v as AnyObject
            case "int32":
                guard let v = field.stringValue else { continue }
                abiType = .int(bits: 32)
                abiValue = v as AnyObject
            case "int64":
                guard let v = field.stringValue else { continue }
                abiType = .int(bits: 64)
                abiValue = v as AnyObject
            case "uint8":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 8)
                abiValue = v as AnyObject
            case "uint16":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 16)
                abiValue = v as AnyObject
            case "uint32":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 32)
                abiValue = v as AnyObject
            case "uint64":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 64)
                abiValue = v as AnyObject
            case "uint256":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 256)
                abiValue = v as AnyObject
            case "uint":
                guard let v = field.stringValue else { continue }
                abiType = .uint(bits: 256)
                abiValue = v as AnyObject
            case "address":
                guard let v = field.stringValue, let address = EthereumAddress(v) else { continue }
                abiType = .address
                abiValue = address as AnyObject
            case "bytes32":
                guard let v = field.stringValue?.stripHexPrefix() else { continue }
                abiType = .bytes(length: 32)
                abiValue = Data(hex: v) as AnyObject
            case "bytes":
                guard let v = field.stringValue?.stripHexPrefix() else { continue }
                abiType = .bytes(length: 32)
                abiValue = EIP712Crypto.keccak256(Data(hex: v)) as AnyObject
            case "string":
                guard let v = field.stringValue?.data(using: .utf8) else { continue }
                abiType = .bytes(length: 32)
                abiValue = EIP712Crypto.keccak256(v) as AnyObject
            default:
                if (field as AnyObject) is NSNull {
                    continue
                } else {
                    preconditionFailure("Not solidity type")
                }
            }
            
            guard let result = ABIEncoder.encodeSingleType(type: abiType, value: abiValue),
                    result.count == 32 else { preconditionFailure("ABI encode error") }
            parametrs.append(result)
        }
        let encoded = parametrs.flatMap { $0.bytes }
        return EIP712Crypto.keccak256(encoded)
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
