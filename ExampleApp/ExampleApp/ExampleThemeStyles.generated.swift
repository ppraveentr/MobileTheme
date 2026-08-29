//
//  ExampleThemeStyles.generated.swift
//  ExampleApp
//
//  Generated from Resources/Theme.json.
//

import Foundation
import Theme

enum CoreTheme {
    typealias SemanticStyleSelection = StyleSelection<SemanticColors>

    struct SemanticColors: SemanticColorSet {
        init() {}

        @ColorValue("textNeutral")
        var textNeutral: ColorID

        @ColorValue("textBrand")
        var textBrand: ColorID
    }

    enum SemanticStyle {
        @StyleValue("Label.Base")
        static var labelBase: SemanticStyleSelection

        @StyleValue("Label.Primary")
        static var labelPrimary: SemanticStyleSelection

        @StyleValue("Label.Brand")
        static var labelBrand: SemanticStyleSelection
    }
}

enum AccountTheme {
    typealias SemanticStyleSelection = StyleSelection<CoreTheme.SemanticColors>

    enum SemanticStyle {
        @StyleValue(module: AccountThemeProvider.self, "Label.Base")
        static var labelBase: SemanticStyleSelection

        @StyleValue(module: AccountThemeProvider.self, "Label.Primary")
        static var labelPrimary: SemanticStyleSelection

        @StyleValue(module: AccountThemeProvider.self, "Label.Brand")
        static var labelBrand: SemanticStyleSelection
    }
}

struct AccountThemeProvider: ThemeModuleProviding {
    static let namespace = "account"
    let themeData: Data
}
