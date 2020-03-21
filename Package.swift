// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "idbcl",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "idbcl", targets: ["idbcl"]),
        .library(name: "libIdbcl", targets: ["libIdbcl"]),
        .library(name: "gui", targets: ["gui"])
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "idbcl",
            dependencies: ["libIdbcl", "SwiftCLI", "gui"]),
        .target(
            name: "libIdbcl",
            dependencies: []),
        .target(
            name: "gui",
            dependencies: ["libIdbcl"]),
        .testTarget(
            name: "idbclTests",
            dependencies: ["libIdbcl"]),
 ]
)
