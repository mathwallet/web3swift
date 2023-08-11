//  web3swift
//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import XCTest
@testable import web3swift

class web3swift_EIP712_Tests: XCTestCase {
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
    
    struct EIP712Domain: EIP712Hashable {
        var name:               String
        var version:            String
        var verifyingContract:  EIP712.Address
    }
    
    struct GasData: EIP712Hashable {
        var gasLimit:               EIP712.UInt256
        var gasPrice:               EIP712.UInt256
        var pctRelayFee:            EIP712.UInt256
        var baseRelayFee:           EIP712.UInt256
    }
    
    struct RelayData: EIP712Hashable {
        var senderAddress:       EIP712.Address
        var senderNonce:         EIP712.UInt256
        var relayWorker:         EIP712.Address
        var paymaster:           EIP712.Address
    }

    struct RelayRequest: EIP712Hashable {
        var target:               EIP712.Address
        var encodedFunction:      EIP712.Bytes
        var gasData:              GasData
        var relayData:            RelayData
    }
    
    func testEIP712Examples() throws {
        let domain = EIP712Domain(name: "GSN Relayed Transaction",
                                  version: "1",
                                  verifyingContract: EthereumAddress("0x6453D37248Ab2C16eBd1A8f782a2CBC65860E60B")!)
        XCTAssertTrue(domain.encodeType() == "EIP712Domain(string name,string version,address verifyingContract)")
        
        let message = RelayRequest(target: EIP712.Address("0x9cf40ef3d1622efe270fe6fe720585b4be4eeeff")!,
                                   encodedFunction: Data(hex: "a9059cbb0000000000000000000000002e0d94754b348d208d64d52d78bcd443afa9fa520000000000000000000000000000000000000000000000000000000000000007"),
                                   gasData: GasData(gasLimit: EIP712.UInt256("39507"),
                                                    gasPrice: EIP712.UInt256("1700000000"),
                                                    pctRelayFee: EIP712.UInt256("70"),
                                                    baseRelayFee: EIP712.UInt256("0")),
                                   relayData: RelayData(senderAddress: EIP712.Address("0x22d491bde2303f2f43325b2108d26f1eaba1e32b")!,
                                                        senderNonce: EIP712.UInt256("3"),
                                                        relayWorker: EIP712.Address("0x3baee457ad824c94bd3953183d725847d023a2cf")!,
                                                        paymaster: EIP712.Address("0x957F270d45e9Ceca5c5af2b49f1b5dC1Abb0421c")!))
        XCTAssertTrue(message.encodeType() == "RelayRequest(address target,bytes encodedFunction,GasData gasData,RelayData relayData)GasData(uint256 gasLimit,uint256 gasPrice,uint256 pctRelayFee,uint256 baseRelayFee)RelayData(address senderAddress,uint256 senderNonce,address relayWorker,address paymaster)")
        XCTAssertTrue(try EIP712.eip712encode(domainSeparator: domain, message: message) == Data(hex: "abc79f527273b9e7bca1b3f1ac6ad1a8431fa6dc34ece900deabcd6969856b5e"))
    }
    
    func testEIP712TypedDataExamples() throws {
        let jsonString = "{\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"RelayRequest\":[{\"name\":\"target\",\"type\":\"address\"},{\"name\":\"encodedFunction\",\"type\":\"bytes\"},{\"name\":\"gasData\",\"type\":\"GasData\"},{\"name\":\"relayData\",\"type\":\"RelayData\"}],\"GasData\":[{\"name\":\"gasLimit\",\"type\":\"uint256\"},{\"name\":\"gasPrice\",\"type\":\"uint256\"},{\"name\":\"pctRelayFee\",\"type\":\"uint256\"},{\"name\":\"baseRelayFee\",\"type\":\"uint256\"}],\"RelayData\":[{\"name\":\"senderAddress\",\"type\":\"address\"},{\"name\":\"senderNonce\",\"type\":\"uint256\"},{\"name\":\"relayWorker\",\"type\":\"address\"},{\"name\":\"paymaster\",\"type\":\"address\"}]},\"domain\":{\"name\":\"GSN Relayed Transaction\",\"version\":\"1\",\"chainId\":42,\"verifyingContract\":\"0x6453D37248Ab2C16eBd1A8f782a2CBC65860E60B\"},\"primaryType\":\"RelayRequest\",\"message\":{\"target\":\"0x9cf40ef3d1622efe270fe6fe720585b4be4eeeff\",\"encodedFunction\":\"0xa9059cbb0000000000000000000000002e0d94754b348d208d64d52d78bcd443afa9fa520000000000000000000000000000000000000000000000000000000000000007\",\"gasData\":{\"gasLimit\":\"39507\",\"gasPrice\":\"1700000000\",\"pctRelayFee\":\"70\",\"baseRelayFee\":\"0\"},\"relayData\":{\"senderAddress\":\"0x22d491bde2303f2f43325b2108d26f1eaba1e32b\",\"senderNonce\":\"3\",\"relayWorker\":\"0x3baee457ad824c94bd3953183d725847d023a2cf\",\"paymaster\":\"0x957F270d45e9Ceca5c5af2b49f1b5dC1Abb0421c\"}}}"
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        debugPrint(typedData.encodeType(typedData.primaryType))
        let digestData = try typedData.digestData()
        XCTAssertEqual(digestData.toHexString(), "abc79f527273b9e7bca1b3f1ac6ad1a8431fa6dc34ece900deabcd6969856b5e")
    }
    
    func testEIP712TypedDataExamples2() throws {
        let jsonString = "{\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"OrderComponents\":[{\"name\":\"offerer\",\"type\":\"address\"},{\"name\":\"zone\",\"type\":\"address\"},{\"name\":\"offer\",\"type\":\"OfferItem[]\"},{\"name\":\"consideration\",\"type\":\"ConsiderationItem[]\"},{\"name\":\"orderType\",\"type\":\"uint8\"},{\"name\":\"startTime\",\"type\":\"uint256\"},{\"name\":\"endTime\",\"type\":\"uint256\"},{\"name\":\"zoneHash\",\"type\":\"bytes32\"},{\"name\":\"salt\",\"type\":\"uint256\"},{\"name\":\"conduitKey\",\"type\":\"bytes32\"},{\"name\":\"counter\",\"type\":\"uint256\"}],\"OfferItem\":[{\"name\":\"itemType\",\"type\":\"uint8\"},{\"name\":\"token\",\"type\":\"address\"},{\"name\":\"identifierOrCriteria\",\"type\":\"uint256\"},{\"name\":\"startAmount\",\"type\":\"uint256\"},{\"name\":\"endAmount\",\"type\":\"uint256\"}],\"ConsiderationItem\":[{\"name\":\"itemType\",\"type\":\"uint8\"},{\"name\":\"token\",\"type\":\"address\"},{\"name\":\"identifierOrCriteria\",\"type\":\"uint256\"},{\"name\":\"startAmount\",\"type\":\"uint256\"},{\"name\":\"endAmount\",\"type\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\"}]},\"primaryType\":\"OrderComponents\",\"domain\":{\"name\":\"Seaport\",\"version\":\"1.5\",\"chainId\":\"1\",\"verifyingContract\":\"0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC\"},\"message\":{\"offerer\":\"0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32\",\"offer\":[{\"itemType\":\"2\",\"token\":\"0xE42caD6fC883877A76A26A16ed92444ab177E306\",\"identifierOrCriteria\":\"7761\",\"startAmount\":\"1\",\"endAmount\":\"1\"}],\"consideration\":[{\"itemType\":\"0\",\"token\":\"0x0000000000000000000000000000000000000000\",\"identifierOrCriteria\":\"0\",\"startAmount\":\"97500000000000000\",\"endAmount\":\"97500000000000000\",\"recipient\":\"0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32\"},{\"itemType\":\"0\",\"token\":\"0x0000000000000000000000000000000000000000\",\"identifierOrCriteria\":\"0\",\"startAmount\":\"2500000000000000\",\"endAmount\":\"2500000000000000\",\"recipient\":\"0x0000a26b00c1F0DF003000390027140000fAa719\"}],\"startTime\":\"1691723303\",\"endTime\":\"1694401703\",\"orderType\":\"0\",\"zone\":\"0x004C00500000aD104D7DBd00e3ae0A5C00560C00\",\"zoneHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"salt\":\"24446860302761739304752683030156737591518664810215442929817494754381829803113\",\"conduitKey\":\"0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000\",\"totalOriginalConsiderationItems\":\"2\",\"counter\":\"0\"}}"
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        debugPrint(typedData.encodeType(typedData.primaryType))
        let digestData = try typedData.digestData()
        XCTAssertEqual(digestData.toHexString(), "6f25a5d5aa693e23d0542b5004ff74ace166517cbc3b08c0a7a875e8335e4db0")
    }
}
