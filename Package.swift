// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Bagel",
    platforms: [
        .iOS(.v12)
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
