//
//  ThemesManagerTests.swift
//  UnitTest
//
//  Created by Praveen Prabhakar on 03/09/22.
//

import SwiftUI
import XCTest
@testable import Theme

final class ThemesManagerTests: XCTestCase {
    func testSharedManagerExists() throws {
        XCTAssertNotNil(ThemesManager.shared)
    }

private struct TestThemeModule: ThemeModuleProviding {
    let namespace = "account"
    let themeData = ThemesManagerTests.semanticThemeData()
}

    func testGenerateModelResolvesSemanticColorsForLightAndDarkMode() throws {
        let model = try ThemeModel.generateModel(Self.semanticThemeData())

        let titleStyle = try XCTUnwrap(model.styles[ThemeStyleID("TitleRW").rawValue])
        let foreground = try XCTUnwrap(titleStyle.forground)
        let background = try XCTUnwrap(titleStyle.background?.color)

        XCTAssertNotNil(foreground.value(.light))
        XCTAssertNotNil(foreground.dark)
        XCTAssertNotNil(background.value(.light))
        XCTAssertNotNil(background.dark)
        XCTAssertEqual(model.themeId, "unit-test")
        XCTAssertEqual(model.schemaVersion, 1)
    }

    func testRegisterModuleNamespacesStylesForTypedLookup() throws {
        try ThemesManager.setupApplicationTheme(Self.semanticThemeData())
        try ThemesManager.register(TestThemeModule())

        let style = ThemesManager.style(ThemeStyleID("account.TitleRW"))
        XCTAssertNotNil(style)
    }

    func testGenerateModelFailsForMissingSemanticAlias() throws {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "broken",
            "palettes": {
                "light": { "neutral": { "0": "#FFFFFF" } }
            },
            "semantic": {
                "light": { "text.primary": "{palette.neutral.900}" }
            }
        }
        """

        XCTAssertThrowsError(try ThemeModel.generateModel(Data(json.utf8))) { error in
            XCTAssertEqual(error as? ThemeResolutionError, .missingToken("palette.neutral.900"))
        }
    }

    func testGenerateModelFailsForCyclicAlias() throws {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "cycle",
            "colors": {
                "a": "{b}",
                "b": "{a}"
            }
        }
        """

        XCTAssertThrowsError(try ThemeModel.generateModel(Data(json.utf8))) { error in
            guard case .cyclicAlias = error as? ThemeResolutionError else {
                return XCTFail("Expected a cyclic alias error, but received: \(error)")
            }
        }
    }

    private static func semanticThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "unit-test",
            "palettes": {
                "light": {
                    "neutral": { "0": "#FFFFFF", "900": "#000000" },
                    "accent": { "100": "#F9DAE0" }
                },
                "dark": {
                    "neutral": { "0": "#FFFFFF", "900": "#121212" },
                    "accent": { "100": "#EC455B" }
                }
            },
            "semantic": {
                "light": {
                    "text.primary": "{palette.neutral.900}",
                    "surface.selected": "{palette.accent.100}"
                },
                "dark": {
                    "text.primary": "{palette.neutral.0}",
                    "surface.selected": "{palette.accent.100}"
                }
            },
            "fonts": {
                "title": { "styleName": "title" }
            },
            "styles": {
                "TitleRW": {
                    "forgroundColor": "text.primary",
                    "font": "title",
                    "background": { "color": "surface.selected" }
                }
            }
        }
        """
        return Data(json.utf8)
    }
}
