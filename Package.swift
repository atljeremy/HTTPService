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
            type: .dynamic,
            targets: ["HTTPService"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HTTPService",
            path: "HTTPService",
            exclude: ["Info.plist"],
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ]
        ),
        .testTarget(
            name: "HTTPServiceTests",
            dependencies: ["HTTPService"],
            path: "HTTPServiceTests",
            exclude: ["Info.plist"]
        )
    ]
)

