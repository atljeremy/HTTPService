// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "HTTPService",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
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
            path: "HTTPService",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "HTTPServiceTests",
            dependencies: ["HTTPService"],
            path: "HTTPServiceTests",
            exclude: ["Info.plist"]
        )
    ]
)

