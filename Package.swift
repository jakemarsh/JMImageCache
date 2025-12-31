// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JMImageCache",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "JMImageCache",
            targets: ["JMImageCache"]
        ),
    ],
    targets: [
        .target(
            name: "JMImageCache",
            dependencies: [],
            path: "Sources/JMImageCache"
        ),
        .testTarget(
            name: "JMImageCacheTests",
            dependencies: ["JMImageCache"],
            path: "Tests/JMImageCacheTests"
        ),
    ]
)
