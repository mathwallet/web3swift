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
        let jsonString = "{\"types\":{\"PermitSingle\":[{\"name\":\"details\",\"type\":\"PermitDetails\"},{\"name\":\"spender\",\"type\":\"address\"},{\"name\":\"sigDeadline\",\"type\":\"uint256\"}],\"PermitDetails\":[{\"name\":\"token\",\"type\":\"address\"},{\"name\":\"amount\",\"type\":\"uint160\"},{\"name\":\"expiration\",\"type\":\"uint48\"},{\"name\":\"nonce\",\"type\":\"uint48\"}],\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}]},\"domain\":{\"name\":\"Permit2\",\"chainId\":\"42161\",\"verifyingContract\":\"0x000000000022d473030f116ddee9f6b43ac78ba3\"},\"primaryType\":\"PermitSingle\",\"message\":{\"details\":{\"token\":\"0x912ce59144191c1204e64559fe8253a0e49e6548\",\"amount\":\"1461501637330902918203684832716283019655932542975\",\"expiration\":\"1714203138\",\"nonce\":\"0\"},\"spender\":\"0x5e325eda8064b456f4781070c0738d849c824258\",\"sigDeadline\":\"1711612938\"}}"
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        let digestData = try typedData.digestData()
        XCTAssertEqual(digestData.toHexString(), "0x57851d73d396c022a4e3ee737560e784bb425251354b4c1868bcda9823f29f64".stripHexPrefix())
    }
    
    func testEIP712TypedDataExamples3() throws {
        let jsonString = "{\"types\":{\"BatchSignedERC721Orders\":[{\"type\":\"address\",\"name\":\"maker\"},{\"type\":\"uint256\",\"name\":\"listingTime\"},{\"type\":\"uint256\",\"name\":\"expiryTime\"},{\"type\":\"uint256\",\"name\":\"startNonce\"},{\"type\":\"address\",\"name\":\"erc20Token\"},{\"type\":\"address\",\"name\":\"platformFeeRecipient\"},{\"type\":\"BasicCollection[]\",\"name\":\"basicCollections\"},{\"type\":\"Collection[]\",\"name\":\"collections\"},{\"type\":\"uint256\",\"name\":\"hashNonce\"}],\"BasicCollection\":[{\"type\":\"address\",\"name\":\"nftAddress\"},{\"type\":\"bytes32\",\"name\":\"fee\"},{\"type\":\"bytes32[]\",\"name\":\"items\"}],\"Collection\":[{\"type\":\"address\",\"name\":\"nftAddress\"},{\"type\":\"bytes32\",\"name\":\"fee\"},{\"type\":\"OrderItem[]\",\"name\":\"items\"}],\"OrderItem\":[{\"type\":\"uint256\",\"name\":\"erc20TokenAmount\"},{\"type\":\"uint256\",\"name\":\"nftId\"}],\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}]},\"domain\":{\"name\":\"ElementEx\",\"version\":\"1.0.0\",\"chainId\":\"137\",\"verifyingContract\":\"0xeaf5453b329eb38be159a872a6ce91c9a8fb0260\"},\"primaryType\":\"BatchSignedERC721Orders\",\"message\":{\"maker\":\"0x588faac6b3aa91bb4cd8127ab357515716541f1b\",\"listingTime\":\"1713358934\",\"expiryTime\":\"1715950990\",\"startNonce\":\"8\",\"erc20Token\":\"0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\",\"platformFeeRecipient\":\"0xd207842d66b715df6ea08cf52f025b9e2ed28788\",\"basicCollections\":[{\"nftAddress\":\"0xb02fc30c2290d7df332397bad70c1852bbc61012\",\"fee\":\"0x000000000000000000c800000000000000000000000000000000000000000000\",\"items\":[\"0x000000001e87f85809dc00000000000000000000000000000000000000000040\"]}],\"collections\":[],\"hashNonce\":\"0\"}}"
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        debugPrint(typedData.encodeType(typedData.primaryType))
        let digestData = try typedData.digestData()
        debugPrint(digestData.toHexString())
        XCTAssertEqual(digestData.toHexString(), "0x97230088997877d444f1b298862f3b915d2708dd5eb345a091ec89b60b7a9dec".stripHexPrefix())
    }
    
}
