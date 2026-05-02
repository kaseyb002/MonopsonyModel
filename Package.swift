// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MonopsonyModel",
    platforms: [
        .iOS(.v17),
        .macOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "MonopsonyModel",
            targets: ["MonopsonyModel"]
        ),
    ],
    targets: [
        .target(
            name: "MonopsonyModel"
        ),
        .testTarget(
            name: "MonopsonyModelTests",
            dependencies: ["MonopsonyModel"]
        ),
    ]
)
