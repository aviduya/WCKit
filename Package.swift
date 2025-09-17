// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// WARNING: This package is experimental and not production-ready

import PackageDescription

let package = Package(
    name: "WCKit",
    platforms: [
        .iOS(.v18),
        .watchOS(.v10),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WCKit",
            targets: ["WCKit"])
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WCKit"
        ),
        .testTarget(
            name: "WCKitTests",
            dependencies: ["WCKit"]
        ),
    ]
)
