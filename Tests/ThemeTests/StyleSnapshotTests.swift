import CryptoKit
import SwiftUI
import XCTest
@testable import Theme

@MainActor
final class StyleSnapshotTests: XCTestCase {
    func testStyledViewSnapshotHashLightMode() async throws {
        try await ThemesManager.setupApplicationTheme(Self.snapshotThemeData())
        let imageData = try renderSnapshot(colorScheme: .light)
        assertSnapshotHash(
            imageData,
            expected: [
                "b1cd46af20d1528b5e8663b582b77272e0275ff45f6ae00e2cd5355bb846bb13", // swift test
                "2d7e7732f5638e0fa5a189c978678b92834c246ff4c80b32f68688095dfe05a0"  // xcodebuild test plan
            ]
        )
    }

    func testStyledViewSnapshotHashDarkMode() async throws {
        try await ThemesManager.setupApplicationTheme(Self.snapshotThemeData())
        let imageData = try renderSnapshot(colorScheme: .dark)
        assertSnapshotHash(
            imageData,
            expected: [
                "c8a8df864fc7056ef01a7b46ee7a98b21eb9b9dc0f17a1fd1ddee85060934076", // swift test
                "db535ff7e26258d06b9f5bc377045913da9bec6d411bdbf0aff83a87380b45cc"  // xcodebuild test plan
            ]
        )
    }

    private func renderSnapshot(colorScheme: ColorScheme) throws -> Data {
        let view = VStack(alignment: .leading, spacing: 12) {
            Text("Primary")
                .padding()
                .style(
                    StyleScope(styleID: ThemeStyleID("Label.Primary")),
                    semanticColor: ColorID("textNeutral")
                )
            Text("Base")
                .style(StyleScope(styleID: ThemeStyleID("Label.Base")))
        }
        .padding()
        .frame(width: 320, height: 180, alignment: .topLeading)
        .environment(\.colorScheme, colorScheme)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1

        #if canImport(UIKit)
        guard let pngData = renderer.uiImage?.pngData() else {
            XCTFail("Failed to render UIImage snapshot.")
            throw SnapshotError.renderFailed
        }
        return pngData
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage else {
            XCTFail("Failed to render NSImage snapshot.")
            throw SnapshotError.renderFailed
        }
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            XCTFail("Failed to convert NSImage snapshot to PNG data.")
            throw SnapshotError.renderFailed
        }
        return pngData
        #else
        XCTFail("Snapshot rendering is unsupported on this platform.")
        throw SnapshotError.unsupportedPlatform
        #endif
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func assertSnapshotHash(_ imageData: Data, expected: Set<String>) {
        let hash = sha256Hex(imageData)
        XCTAssertTrue(expected.contains(hash), "Unexpected snapshot hash: \(hash)")
    }

    private static func snapshotThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "snapshot-test",
            "palettes": {
                "light": {
                    "neutral": { "0": "#FFFFFF", "50": "#F0F2F5", "900": "#000000" },
                    "brand": { "600": "#2673DD" },
                    "status": { "success": "#44CC77" },
                    "accent": { "100": "#F9DAE0" }
                },
                "dark": {
                    "neutral": { "0": "#FFFFFF", "50": "#222222", "900": "#121212" },
                    "brand": { "600": "#EE2C4A" },
                    "status": { "success": "#309053" },
                    "accent": { "100": "#EC455B" }
                }
            },
            "semantic": {
                "light": {
                    "surfaceSelected": "{palette.accent.100}",
                    "textNeutral": "{palette.neutral.900}",
                    "borderSuccess": "{palette.status.success}"
                },
                "dark": {
                    "surfaceSelected": "{palette.accent.100}",
                    "textNeutral": "{palette.neutral.0}",
                    "borderSuccess": "{palette.status.success}"
                }
            },
            "fonts": {
                "title": { "styleName": "title" }
            },
            "borders": {
                "cardSuccess": {
                    "color": "borderSuccess",
                    "radius": [10, 0, 0, 10],
                    "thickness": 2
                }
            },
            "styles": {
                "Label.Base": {
                    "font": "title"
                },
                "Label.Primary": {
                    "font": "title",
                    "border": "cardSuccess",
                    "background": {
                        "color": "surfaceSelected"
                    }
                }
            }
        }
        """
        return Data(json.utf8)
    }
}

private enum SnapshotError: Error {
    case renderFailed
    case unsupportedPlatform
}
