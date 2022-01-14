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
    
    struct EIP712Domain: EIP712Hashable {
        var name:               String
        var version:            String
    }

    struct Vote: EIP712Hashable {
        var from:               EIP712.Address
        var space:              String
        var timestamp:          UInt64
        var proposal:           EIP712.Bytes32
        var choice:             UInt32
        var metadata:           String
    }
    
    func testEIP712Examples() throws {
        let domain = EIP712Domain(name: "snapshot", version: "0.1.4")
        XCTAssertTrue(domain.encodeType() == "EIP712Domain(string name,string version)")
        
        let message = Vote(from: EIP712.Address("0x306bb8081c7dd356ea951795ce4072e6e4bfdc32")!,
                                             space: "pancake",
                                             timestamp: 1642060678,
                                             proposal: EIP712.Bytes32(data: Data(hex: "08706912b77cef36d6da1ba408a11590a8a8fb79b50d4b9212599e13947fedb1")),
                                             choice: 1,
                                             metadata: "{}")
        XCTAssertTrue(message.encodeType() == "Vote(address from,string space,uint64 timestamp,bytes32 proposal,uint32 choice,string metadata)")
        XCTAssertTrue(try EIP712.eip712encode(domainSeparator: domain, message: message) == Data(hex: "40122d8c04cce1df24d222717b8d7d1cb3537c79fa1a83790659df8e29becc27"))
    }
    
    func testEIP712TypedDataExamples() throws {
        let jsonString = "{\"types\":{\"Vote\":[{\"name\":\"from\",\"type\":\"address\"},{\"name\":\"space\",\"type\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint64\"},{\"name\":\"proposal\",\"type\":\"bytes32\"},{\"name\":\"choice\",\"type\":\"uint32\"},{\"name\":\"metadata\",\"type\":\"string\"}],\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"}]},\"domain\":{\"name\":\"snapshot\",\"version\":\"0.1.4\"},\"primaryType\":\"Vote\",\"message\":{\"from\":\"0x306bb8081c7dd356ea951795ce4072e6e4bfdc32\",\"space\":\"pancake\",\"timestamp\":\"1642060678\",\"proposal\":\"0x08706912b77cef36d6da1ba408a11590a8a8fb79b50d4b9212599e13947fedb1\",\"choice\":\"1\",\"metadata\":\"{}\"}}"
        let data = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        debugPrint(data.digest.toHexString())
    }
}
