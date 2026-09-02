//
//  ExampleThemeStyles.generated.swift
//  ExampleApp
//
//  Generated from Resources/Theme.json.
//

import Foundation
import Theme

enum CoreTheme {
    struct ColorSet: SemanticColor {
        init() {}

        @ColorValue("textNeutral")
        var textNeutral: ColorID

        @ColorValue("textBrand")
        var textBrand: ColorID
    }
}

extension SemanticStyle where Colors == CoreTheme.ColorSet {
    @StyleValue("Label.Base")
    static var labelBase: Self

    @StyleValue("Label.Primary")
    static var labelPrimary: Self

    @StyleValue("Label.Brand")
    static var labelBrand: Self
}

// AccountThemeProvider

extension SemanticStyle where Colors == CoreTheme.ColorSet {
    @StyleValue(module: AccountThemeProvider.self, "Label.Base")
    static var accountLabelBase: Self

    @StyleValue(module: AccountThemeProvider.self, "Label.Primary")
    static var accountLabelPrimary: Self

    @StyleValue(module: AccountThemeProvider.self, "Label.Brand")
    static var accountLabelBrand: Self
}

struct AccountThemeProvider: ThemeModuleProviding {
    static let namespace = "account"
    let themeData: Data
}
