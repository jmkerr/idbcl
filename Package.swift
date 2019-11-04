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
    dependencies: [],
    targets: [
        .target(
            name: "idbcl",
            dependencies: ["libIdbcl"]),
        .target(
            name: "libIdbcl",
            dependencies: []),
        .testTarget(
            name: "idbclTests",
            dependencies: ["libIdbcl"]),
 ]
)
