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
    dependencies: [
        .package(url: "https://github.com/MrKai77/Luminare", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "OpenWith",
            dependencies: [
                .product(name: "Luminare", package: "Luminare")
            ],
            path: "Sources",
            resources: [
                .process("../Resources/Assets.xcassets")
            ]
        )
    ]
)
