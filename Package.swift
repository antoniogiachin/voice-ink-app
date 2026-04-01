// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoceInk",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VoceInk",
            path: "Sources/VoceInk",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
            ]
        ),
        .testTarget(
            name: "VoceInkTests",
            dependencies: ["VoceInk"],
            path: "Tests/VoceInkTests"
        ),
    ]
)
