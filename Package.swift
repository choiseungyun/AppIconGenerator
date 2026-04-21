// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppIconGenerator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AppIconGenerator",
            targets: ["AppIconGeneratorApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppIconGeneratorApp"
            , path: "Sources/AppIconGeneratorApp"
        )
    ]
)
