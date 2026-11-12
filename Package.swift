// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileTheme",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(name: "MobileTheme", targets: ["Theme"]),
        .executable(name: "theme-cli", targets: ["ThemeCLI"])
    ],
    dependencies: [
        // .package(url: "https://github.com/apple/swift-docc-plugin", branch: "main")
    ],
    targets: [
        // Theme
        // ThemeCore: pure Swift (no SwiftUI) schema + validation, usable from tooling on any platform
        .target(name: "ThemeCore"),
        // Theme: SwiftUI runtime (re-exports ThemeCore)
        .target(name: "Theme", dependencies: ["ThemeCore"]),
        .executableTarget(name: "ThemeCLI", dependencies: ["ThemeCore"]),
        .testTarget(name: "ThemeCoreTests", dependencies: ["ThemeCore"]),
        .testTarget(name: "ThemeTests", dependencies: ["Theme"])
    ],
    swiftLanguageModes: [.v5]
)
