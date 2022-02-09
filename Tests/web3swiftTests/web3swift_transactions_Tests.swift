//  web3swift
//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import XCTest
import CryptoSwift
import BigInt
//import EthereumAddress

@testable import web3swift

class web3swift_transactions_Tests: XCTestCase {
    
    func testTransaction() {
        do {
            var transaction = EthereumTransaction(nonce: BigUInt(9),
                                                  gasPrice: BigUInt("20000000000"),
                                                  gasLimit: BigUInt(21000),
                                                  to: EthereumAddress("0x3535353535353535353535353535353535353535")!,
                                                  value: BigUInt("1000000000000000000"),
                                                  data: Data(),
                                                  v: BigUInt(0),
                                                  r: BigUInt(0),
                                                  s: BigUInt(0))
            transaction.chainID = BigUInt(1)
            let privateKeyData = Data.fromHex("0x4646464646464646464646464646464646464646464646464646464646464646")!
            let publicKey = Web3.Utils.privateToPublic(privateKeyData, compressed: false)
            let sender = Web3.Utils.publicToAddress(publicKey!)

            let hash = transaction.hashForSignature(chainID: BigUInt(1))
            let expectedHash = "0xdaf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53".stripHexPrefix()
            XCTAssert(hash!.toHexString() == expectedHash, "Transaction signature failed")
            try Web3Signer.EIP155Signer.sign(transaction: &transaction, privateKey: privateKeyData, useExtraEntropy: false)
            print(transaction)
            XCTAssert(transaction.v == UInt8(37), "Transaction signature failed")
            XCTAssert(sender == transaction.sender)
            print(transaction.encode()!.toHexString())
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testTransactionEIP1559() {
        do {
            var transaction = EthereumTransaction(maxPriorityFeePerGas: BigUInt("59682f00", radix: 16)!, maxFeePerGas: BigUInt("1b50d4af77", radix: 16)!, gasLimit: BigUInt("5208", radix: 16)!, to: EthereumAddress("0x306bb8081c7dd356ea951795ce4072e6e4bfdc32")!, value: BigUInt(0), data: Data(), chainID: BigUInt(1))
            transaction.nonce = BigUInt(473)
            
            let privateKeyData = Data.fromHex("0x4646464646464646464646464646464646464646464646464646464646464646")!
            let publicKey = Web3.Utils.privateToPublic(privateKeyData, compressed: false)
            let sender = Web3.Utils.publicToAddress(publicKey!)
            
            try Web3Signer.EIP1559Signer.sign(transaction: &transaction, privateKey: privateKeyData, useExtraEntropy: false)
            print(transaction)
            XCTAssert(transaction.v == UInt8(0), "Transaction signature failed")
            XCTAssert(sender == transaction.sender)
            let expectedTxid = "0xb5308f2b28dc00c7342fa49b25e857aa0b02a9b353968486bf46154df6478bd9"
            XCTAssert(expectedTxid == transaction.txid!)
            print(transaction.encode()!.toHexString())
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testEstimateGas() throws {
        var transaction = EthereumTransaction(gasPrice: BigUInt(100000000000),
                                              gasLimit: BigUInt("50000"),
                                              to: EthereumAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")!,
                                              value: BigUInt(0),
                                              data: Data(hex: "095ea7b3000000000000000000000000e5c783ee536cf5e63e792988335c4255169be4e1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        transaction.nonce = BigUInt(24)
        
        let web3 = Web3.InfuraMainnetWeb3()
        let estimateGas = try web3.eth.estimateGas(transaction, transactionOptions: nil)
        debugPrint(estimateGas.description)
    }
    
    func testEstimateGas_EIP1559() throws {
        var transaction = EthereumTransaction(maxPriorityFeePerGas: BigUInt("1500000000"),
                                              maxFeePerGas: BigUInt("84215025019"),
                                              gasLimit: BigUInt("50000"),
                                              to: EthereumAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")!,
                                              value: BigUInt(0),
                                              data: Data(hex: "095ea7b3000000000000000000000000e5c783ee536cf5e63e792988335c4255169be4e1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"),
                                              chainID: BigUInt(1))
        transaction.nonce = BigUInt(24)
        
        let web3 = Web3.InfuraMainnetWeb3()
        let estimateGas = try web3.eth.estimateGas(transaction, transactionOptions: nil)
        debugPrint(estimateGas.description)
    }
    
    func testEthSendExample() {
        do {
            let web3 = Web3.InfuraMainnetWeb3()
            let sendToAddress = EthereumAddress("0xe22b8979739D724343bd002F9f432F5990879901")!
            let tempKeystore = try! EthereumKeystoreV3(password: "")
            let keystoreManager = KeystoreManager([tempKeystore!])
            web3.addKeystoreManager(keystoreManager)
            let contract = web3.contract(Web3.Utils.coldWalletABI, at: sendToAddress, abiVersion: 2)
            let value = Web3.Utils.parseToBigUInt("1.0", units: .eth)
            let from = keystoreManager.addresses?.first
            let writeTX = contract!.write("fallback")!
            writeTX.transactionOptions.from = from
            writeTX.transactionOptions.value = value
            let _ = try writeTX.sendPromise(password: "").wait()
        } catch Web3Error.nodeError(let descr) {
            guard descr == "insufficient funds for gas * price + value" else {return XCTFail()}
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testTransactionReceipt() throws {
        let web3 = Web3.InfuraMainnetWeb3()
        let response = try web3.eth.getTransactionReceipt("0xa111166b3054c9e77d02b6d7c5f0f65720ea1c3749ca10d48919f997cdd98fdc")
        debugPrint(response)
        XCTAssert(response.status == .ok)
    }
    
    func testTransactionDetails() throws {
        let web3 = Web3.InfuraMainnetWeb3()
        // Legacy
        let response = try web3.eth.getTransactionDetails("0x5b596e2e2c3375ac1c4d37d668e383ece6db0d090306c9ebe172a0c7dd48ba23")
        print(response)
        XCTAssert(response.transaction.txid == "0x5b596e2e2c3375ac1c4d37d668e383ece6db0d090306c9ebe172a0c7dd48ba23")
        
        // EIP-1559
        let response2 = try web3.eth.getTransactionDetails("0xa111166b3054c9e77d02b6d7c5f0f65720ea1c3749ca10d48919f997cdd98fdc")
        print(response)
        XCTAssert(response2.transaction.txid == "0xa111166b3054c9e77d02b6d7c5f0f65720ea1c3749ca10d48919f997cdd98fdc")
    }
    
    
    func getKeystoreData() -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "key", ofType: "json") else {return nil}
        guard let data = NSData(contentsOfFile: path) else {return nil}
        return data as Data
    }
    
    func testGenerateDummyKeystore() {
        let keystore = try! EthereumKeystoreV3.init(password: "web3swift")
        let dump = try! keystore!.serialize()
        let jsonString = String.init(data: dump!, encoding: .ascii)
        print(jsonString!)
    }
}
