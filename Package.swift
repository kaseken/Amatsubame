// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Amatsubame",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "LocalHTTPServer", path: "Sources/LocalHTTPServer"),
        .executableTarget(name: "Amatsubame", path: "Sources/Amatsubame"),
        .executableTarget(
            name: "TestServer",
            dependencies: ["LocalHTTPServer"],
            path: "Sources/TestServer",
            resources: [.process("Resources")],
        ),
        .testTarget(
            name: "AmatsubameTests",
            dependencies: ["Amatsubame", "LocalHTTPServer"],
            path: "Tests/AmatsubameTests",
        ),
    ],
)
