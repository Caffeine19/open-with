// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DefaultAppsManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DefaultAppsManager",
            targets: ["DefaultAppsManager"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DefaultAppsManager",
            path: "Sources",
            resources: [
                .process("../Resources/Assets.xcassets")
            ]
        )
    ]
)
