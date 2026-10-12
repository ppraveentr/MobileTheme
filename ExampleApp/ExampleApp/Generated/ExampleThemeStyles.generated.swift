//
//  ExampleThemeStyles.generated.swift
//  ExampleApp
//
//  Generated from Resources/Theme.json.
//

import Foundation
import Theme

enum CoreTheme {
    enum Styles {
        static let labelBase = ThemeStyleID("Label.Base")
        static let labelPrimary = ThemeStyleID("Label.Primary")
        static let labelBrand = ThemeStyleID("Label.Brand")
    }

    enum Colors {
        static let textNeutral = ColorID("textNeutral")
        static let textBrand = ColorID("textBrand")
    }

    struct ColorSet: SemanticColor {
        init() {}

        @ColorValue("textNeutral")
        var textNeutral: ColorID

        @ColorValue("textBrand")
        var textBrand: ColorID
    }
}

extension SemanticStyle where Colors == CoreTheme.ColorSet {
    static var labelBase: Self { .style(CoreTheme.Styles.labelBase) }
    static var labelPrimary: Self { .style(CoreTheme.Styles.labelPrimary) }
    static var labelBrand: Self { .style(CoreTheme.Styles.labelBrand) }
}
