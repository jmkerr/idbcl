// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "idbcl",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(name: "idbcl", targets: ["idbcl"]),
        .library(name: "libIdbcl", targets: ["libIdbcl"])
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "idbcl",
            dependencies: ["libIdbcl", "SwiftCLI"]),
        .target(
            name: "libIdbcl",
            dependencies: []),
        .testTarget(
            name: "idbclTests",
            dependencies: ["libIdbcl"]),
 ]
)
