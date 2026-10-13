// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AirconKit",
    platforms: [.macOS(.v26)],
    products: [.library(name: "AirconKit", targets: ["AirconKit"])],
    targets: [
        .target(name: "AirconKit"),
        .testTarget(name: "AirconKitTests", dependencies: ["AirconKit"]),
    ]
)
