// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Web3swift",
  platforms: [
    .macOS(.v10_12), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "web3swift", targets: ["web3swift"]),
    ],
  dependencies: [
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.0.0"),
    .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.8.4"),
    .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1"),
    .package(url: "https://github.com/mathwallet/BIP39swift.git", from: "1.0.1"),
    .package(url: "https://github.com/mathwallet/Secp256k1Swift.git", from: "1.2.0")
],
  targets: [
    .target(
      name: "web3swift",
      dependencies: ["BigInt", "PromiseKit", "Starscream", "Secp256k1Swift", .product(name: "BIP32Swift", package: "Secp256k1Swift"), "BIP32Swift", "BIP39swift"],
      exclude: []),
    .testTarget(
      name: "web3swiftTests",
      dependencies: ["web3swift"]),
    ]
)
