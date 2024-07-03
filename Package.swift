// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSAML",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "SwiftSAML",
            targets: ["SwiftSAML"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
//        .systemLibrary(
//            name: "CZlib",
//            pkgConfig: "zlib",
//            providers: [
//                .brew(["zlib"]),
//                .apt(["zlib1g-dev"])
//            ]
//        ),
        .target(
            name: "SwiftSAML",
            dependencies: [
                "SWXMLHash",
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "SwiftSAMLTests",
            dependencies: ["SwiftSAML"]),
    ]
)
