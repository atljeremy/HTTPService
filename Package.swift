// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "HTTPService",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "HTTPService",
            targets: ["HTTPService"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HTTPService",
            dependencies: []
        ),
        .testTarget(
            name: "HTTPServiceTests",
            dependencies: ["HTTPService"]
        )
    ]
)

