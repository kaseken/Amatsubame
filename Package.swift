// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Amatsubame",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "Amatsubame", path: "Sources/Amatsubame"),
        .testTarget(
            name: "AmatsubameTests",
            dependencies: ["Amatsubame"],
            path: "Tests/AmatsubameTests"
        ),
    ]
)
