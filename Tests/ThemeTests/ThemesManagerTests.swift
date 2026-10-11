//
//  ThemesManagerTests.swift
//  UnitTest
//
//  Created by Praveen Prabhakar on 03/09/22.
//

import SwiftUI
import XCTest
@testable import Theme

@MainActor
final class ThemesManagerTests: XCTestCase {
    func testSharedManagerExists() throws {
        XCTAssertNotNil(ThemesManager.shared)
    }

struct TestThemeModule: ThemeModuleProviding {
    static let namespace = "account"
    let themeData: Data
}

private struct BaseFallbackThemeModule: ThemeModuleProviding {
    static let namespace = "account"
    let themeData: Data
}

struct AccountSemanticColors: SemanticColor {
    init() {}

    @ColorValue(module: TestThemeModule.self, "text.primary")
    var textPrimary: ColorID
}

private enum AccountSemanticStyle {
    @StyleValue(module: TestThemeModule.self, "Label.Primary")
    static var labelPrimary: SemanticStyle<AccountSemanticColors>
}

    func testGenerateModelResolvesSemanticColorsForLightAndDarkMode() throws {
        let model = try ThemeModel.generateModel(Self.semanticThemeData())

        let titleStyle = try XCTUnwrap(model.styles[ThemeStyleID("Label.Primary").rawValue])
        let foreground = try XCTUnwrap(titleStyle.forground)
        let background = try XCTUnwrap(titleStyle.background?.color)

        XCTAssertNotNil(foreground.value(.light))
        XCTAssertNotNil(foreground.dark)
        XCTAssertNotNil(background.value(.light))
        XCTAssertNotNil(background.dark)
        XCTAssertEqual(model.themeId, "unit-test")
        XCTAssertEqual(model.schemaVersion, 1)
    }

    func testRegisterModuleNamespacesStylesForTypedLookup() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticThemeData())
        try await ThemesManager.register(TestThemeModule(themeData: Self.semanticThemeData()))

        let style = await ThemesManager.style(ThemeStyleID("account.Label.Primary"))
        XCTAssertNotNil(style)
    }

    func testRegisterModuleCannotOverrideExistingNamespacedStyles() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticThemeData())
        try await ThemesManager.register(TestThemeModule(themeData: Self.semanticThemeData()))

        do {
            try await ThemesManager.register(TestThemeModule(themeData: Self.semanticThemeData()))
            XCTFail("Expected duplicate style error.")
        } catch {
            XCTAssertEqual(error as? ThemeMergeError, .duplicateStyle("account.Label.Primary"))
        }
    }

    func testStyleValueSupportsModuleNamespacedGeneratedValues() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticThemeData())
        try await ThemesManager.register(TestThemeModule(themeData: Self.semanticThemeData()))

        XCTAssertEqual(AccountSemanticColors().textPrimary.rawValue, "account.text.primary")
        let generatedStyleID = AccountSemanticStyle.labelPrimary.selection.semanticStyle.styleID
        XCTAssertEqual(generatedStyleID.rawValue, "account.Label.Primary")
        let style = await ThemesManager.style(generatedStyleID)
        XCTAssertNotNil(style)
    }

    func testStaticMemberStyleSelectionSupportsLeadingDotSyntax() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticThemeData())
        try await ThemesManager.register(TestThemeModule(themeData: Self.semanticThemeData()))

        let selection: SemanticStyle<AccountSemanticColors> = .labelPrimaryDot
        XCTAssertEqual(selection.selection.semanticStyle.styleID.rawValue, "account.Label.Primary")
        let style = await ThemesManager.style(selection.selection.semanticStyle.styleID)
        XCTAssertNotNil(style)
    }

    func testModuleStyleCanReferenceBaseTokens() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticBackgroundThemeData())
        try await ThemesManager.register(BaseFallbackThemeModule(themeData: Self.moduleReferencingBaseThemeData()))

        let moduleStyle = await ThemesManager.style(ThemeStyleID("account.Label.Linked"))
        let style = try XCTUnwrap(moduleStyle)
        XCTAssertNotNil(style.forground)
        XCTAssertNotNil(style.background)
        XCTAssertNotNil(style.font)
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

    func testGenerateModelResolvesSemanticBorderTokenWithoutModeLayer() throws {
        let model = try ThemeModel.generateModel(Self.semanticBorderThemeData())
        let titleStyle = try XCTUnwrap(model.styles[ThemeStyleID("Label.Primary").rawValue])
        let border = try XCTUnwrap(titleStyle.border)
        let borderColor = try XCTUnwrap(border.color)

        XCTAssertEqual(border.thickness, 2)
        XCTAssertEqual(border.radius ?? [], [10, 0, 0, 10])
        XCTAssertNotNil(borderColor.value(.light))
        XCTAssertNotNil(borderColor.value(.dark))
    }

    func testGenerateModelResolvesSemanticBackgroundTokenWithoutModeLayer() throws {
        let model = try ThemeModel.generateModel(Self.semanticBackgroundThemeData())
        let titleStyle = try XCTUnwrap(model.styles[ThemeStyleID("Label.Primary").rawValue])
        let background = try XCTUnwrap(titleStyle.background)
        let backgroundColor = try XCTUnwrap(background.color)

        XCTAssertEqual(background.ignoringSafeArea, false)
        XCTAssertNotNil(backgroundColor.value(.light))
        XCTAssertNotNil(backgroundColor.value(.dark))
    }

    func testStyleModifierCanApplySemanticForegroundWithoutStyleForeground() async throws {
        try await ThemesManager.setupApplicationTheme(Self.semanticForegroundOverrideThemeData())

        let style = await ThemesManager.style(ThemeStyleID("Body"))
        let baseStyle = try XCTUnwrap(style)
        XCTAssertNil(baseStyle.forground)

        let resolvedStyle = await ThemesManager.resolvedStyle(
            styleID: ThemeStyleID("Body"),
            foregroundColorID: ColorID("text.brand")
        )
        let overridden = try XCTUnwrap(resolvedStyle)
        let foreground = try XCTUnwrap(overridden.forground)
        XCTAssertNotNil(foreground.value(.light))
        XCTAssertNotNil(foreground.value(.dark))
    }

    func testGenerateModelResolvesNestedStyleTemplateKeys() throws {
        let model = try ThemeModel.generateModel(Self.nestedStyleThemeData())
        XCTAssertNotNil(model.styles[ThemeStyleID("Label.Base").rawValue])
        XCTAssertNotNil(model.styles[ThemeStyleID("Label.Primary").rawValue])
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
                "Label.Primary": {
                    "forgroundColor": "text.primary",
                    "font": "title",
                    "background": { "color": "surface.selected" }
                }
            }
        }
        """
        return Data(json.utf8)
    }

    private static func semanticBorderThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "unit-test-border",
            "palettes": {
                "light": {
                    "neutral": { "0": "#FFFFFF", "900": "#000000" },
                    "status": { "success": "#44CC77" }
                },
                "dark": {
                    "neutral": { "0": "#FFFFFF", "900": "#121212" },
                    "status": { "success": "#309053" }
                }
            },
            "semantic": {
                "light": {
                    "text.primary": "{palette.neutral.900}",
                    "border.success": "{palette.status.success}"
                },
                "dark": {
                    "text.primary": "{palette.neutral.0}",
                    "border.success": "{palette.status.success}"
                }
            },
            "borders": {
                "card.success": {
                    "color": "border.success",
                    "radius": [10, 0, 0, 10],
                    "thickness": 2
                }
            },
            "fonts": {
                "title": { "styleName": "title" }
            },
            "styles": {
                "Label.Primary": {
                    "forgroundColor": "text.primary",
                    "font": "title",
                    "border": "card.success"
                }
            }
        }
        """
        return Data(json.utf8)
    }

    private static func semanticForegroundOverrideThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "unit-test-foreground-override",
            "palettes": {
                "light": {
                    "neutral": { "0": "#FFFFFF" },
                    "brand": { "600": "#2673DD" }
                },
                "dark": {
                    "neutral": { "0": "#FFFFFF" },
                    "brand": { "600": "#EE2C4A" }
                }
            },
            "semantic": {
                "light": {
                    "text.brand": "{palette.brand.600}"
                },
                "dark": {
                    "text.brand": "{palette.brand.600}"
                }
            },
            "fonts": {
                "body": { "styleName": "body" }
            },
            "styles": {
                "Body": {
                    "font": "body"
                }
            }
        }
        """
        return Data(json.utf8)
    }

    private static func semanticBackgroundThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "unit-test-background",
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
            "backgrounds": {
                "card.selected": {
                    "color": "surface.selected",
                    "ignoringSafeArea": false
                }
            },
            "fonts": {
                "title": { "styleName": "title" }
            },
            "styles": {
                "Label.Primary": {
                    "forgroundColor": "text.primary",
                    "font": "title",
                    "background": "card.selected"
                }
            }
        }
        """
        return Data(json.utf8)
    }

    private static func nestedStyleThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "unit-test-nested-styles",
            "palettes": {
                "light": {
                    "neutral": { "0": "#FFFFFF", "900": "#000000" }
                },
                "dark": {
                    "neutral": { "0": "#FFFFFF", "900": "#121212" }
                }
            },
            "semantic": {
                "light": {
                    "text.primary": "{palette.neutral.900}"
                },
                "dark": {
                    "text.primary": "{palette.neutral.0}"
                }
            },
            "fonts": {
                "title": { "styleName": "title" }
            },
            "styles": {
                "Label": {
                    "Base": {
                        "font": "title"
                    },
                    "Primary": {
                        "forgroundColor": "text.primary",
                        "font": "title"
                    }
                }
            }
        }
        """
        return Data(json.utf8)
    }

    private static func moduleReferencingBaseThemeData() -> Data {
        let json = """
        {
            "schemaVersion": 1,
            "themeId": "account-module-fallback",
            "styles": {
                "Label.Linked": {
                    "forgroundColor": "text.primary",
                    "font": "title",
                    "background": "card.selected"
                }
            }
        }
        """
        return Data(json.utf8)
    }
}

extension SemanticStyle where Colors == ThemesManagerTests.AccountSemanticColors {
    static var labelPrimaryDot: Self { .style(module: ThemesManagerTests.TestThemeModule.self, "Label.Primary") }
}
