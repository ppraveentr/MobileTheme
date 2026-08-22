// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileTheme",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "MobileTheme", targets: ["Theme"])
    ],
    dependencies: [
        // .package(url: "https://github.com/apple/swift-docc-plugin", branch: "main")
    ],
    targets: [
        // Theme
        .target(name: "Theme"),
        .testTarget(name: "ThemeTests", dependencies: ["Theme"])
    ]
)
