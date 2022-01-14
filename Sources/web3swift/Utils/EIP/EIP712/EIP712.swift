//  web3swift
//
//  Created by Forrest.
//  Copyright © 2022 MATH. All rights reserved.
//

import BigInt
import CryptoSwift
import Foundation

/// Protocol defines EIP712 struct encoding
public protocol EIP712Hashable {
    var typehash: Data { get }
    func hash() throws -> Data
}

public class EIP712 {
    public struct Bytes32 {
        public var data: Data
        public init(data: Data) {
            self.data = data
        }
    }
    public typealias UInt256 = BigUInt
    public typealias Address = EthereumAddress
    public typealias Bytes = Data
    
    // Encode functions
    public static func eip712encode(domainSeparator: EIP712Hashable, message: EIP712Hashable) throws -> Data {
        let data = try Data([UInt8(0x19), UInt8(0x01)]) + domainSeparator.hash() + message.hash()
        return EIP712Crypto.keccak256(data)
    }
}
public extension EIP712.Address {
    static var zero: Self {
        EthereumAddress(Data(count: 20))!
    }
}

public extension EIP712Hashable {
    private var _typeName: String {
        let fullName = "\(Self.self)"
        let name = fullName.components(separatedBy: ".").last ?? fullName
        return name
    }
    
    private func dependencies() -> [EIP712Hashable] {
        let dependencies = Mirror(reflecting: self).children
            .compactMap { $0.value as? EIP712Hashable }
            .flatMap { [$0] + $0.dependencies() }
        return dependencies
    }
    
    private func encodePrimaryType() -> String {
        let parametrs: [String] = Mirror(reflecting: self).children.compactMap { key, value in
            guard let key = key else { return nil }
            
            func checkIfValueIsNil(value: Any) -> Bool {
                let mirror = Mirror(reflecting : value)
                if mirror.displayStyle == .optional {
                    if mirror.children.count == 0 {
                        return true
                    }
                }
                
                return false
            }
            
            guard !checkIfValueIsNil(value: value) else { return nil }
            
            let typeName: String
            switch value {
            case is EIP712.UInt256: typeName = "uint256"
            case is EIP712.Address: typeName = "address"
            case is EIP712.Bytes32: typeName = "bytes32"
            case is EIP712.Bytes: typeName = "bytes"
            case let hashable as EIP712Hashable: typeName = hashable._typeName
            default: typeName = "\(type(of: value))".lowercased()
            }
            return typeName + " " + key
        }
        return self._typeName + "(" + parametrs.joined(separator: ",") + ")"
    }
    
    func encodeType() -> String {
        let dependencies = self.dependencies().map { $0.encodePrimaryType() }
        let selfPrimaryType = self.encodePrimaryType()
        
        let result = Set(dependencies).filter { $0 != selfPrimaryType }
        return selfPrimaryType + result.sorted().joined()
    }
    
    // MARK: - Default implementation
    
    var typehash: Data {
        EIP712Crypto.keccak256(encodeType())
    }
    
    func hash() throws -> Data {
        typealias SolidityValue = (value: Any, type: ABI.Element.ParameterType)
        var parametrs: [Data] = [self.typehash]
        for case let (_, field) in Mirror(reflecting: self).children {
            let result: Data
            switch field {
            case is Bool:
                result = ABIEncoder.encodeSingleType(type: .bool, value: field as AnyObject)!
            case is Int8:
                result = ABIEncoder.encodeSingleType(type: .int(bits: 8), value: field as AnyObject)!
            case is Int16:
                result = ABIEncoder.encodeSingleType(type: .int(bits: 16), value: field as AnyObject)!
            case is Int32:
                result = ABIEncoder.encodeSingleType(type: .int(bits: 32), value: field as AnyObject)!
            case is Int64:
                result = ABIEncoder.encodeSingleType(type: .int(bits: 64), value: field as AnyObject)!
            case is UInt8:
                result = ABIEncoder.encodeSingleType(type: .uint(bits: 8), value: field as AnyObject)!
            case is UInt16:
                result = ABIEncoder.encodeSingleType(type: .uint(bits: 16), value: field as AnyObject)!
            case is UInt32:
                result = ABIEncoder.encodeSingleType(type: .uint(bits: 32), value: field as AnyObject)!
            case is UInt64:
                result = ABIEncoder.encodeSingleType(type: .uint(bits: 64), value: field as AnyObject)!
            case is EIP712.UInt256:
                result = ABIEncoder.encodeSingleType(type: .uint(bits: 256), value: field as AnyObject)!
            case is EIP712.Address:
                result = ABIEncoder.encodeSingleType(type: .address, value: field as AnyObject)!
            case let bytes32 as EIP712.Bytes32:
                result = bytes32.data
            case let data as EIP712.Bytes:
                result = EIP712Crypto.keccak256(data)
            case let string as String:
                result = EIP712Crypto.keccak256(string)
            case let hashable as EIP712Hashable:
                result = try hashable.hash()
            default:
                if (field as AnyObject) is NSNull {
                    continue
                } else {
                    preconditionFailure("Not solidity type")
                }
            }
            guard result.count == 32 else { preconditionFailure("ABI encode error") }
            parametrs.append(result)
        }
        let encoded = parametrs.flatMap { $0.bytes }
        return EIP712Crypto.keccak256(encoded)
    }
}

struct EIP712Crypto {
    // MARK: - keccak256
    static func keccak256(_ data: [UInt8]) -> Data {
        Data(SHA3(variant: .keccak256).calculate(for: data))
    }

    static func keccak256(_ string: String) -> Data {
        keccak256(Array(string.utf8))
    }

    static func keccak256(_ data: Data) -> Data {
        keccak256(data.bytes)
    }
}
