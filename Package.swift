// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenWith",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OpenWith",
            targets: ["OpenWith"]
        )
    ],
    targets: [
        .executableTarget(
            name: "OpenWith",
            path: "Sources",
            resources: [
                .process("../Resources/Assets.xcassets")
            ]
        )
    ]
)
