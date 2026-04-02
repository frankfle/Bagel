// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Bagel",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Bagel", targets: ["Bagel"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Bagel",
            dependencies: [],
            path: "iOS/Source",
            publicHeadersPath: ""
        )
    ]
)
