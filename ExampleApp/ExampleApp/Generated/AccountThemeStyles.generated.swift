//
//  AccountThemeStyles.generated.swift
//  ExampleApp
//
//  Generated from Resources/AccountTheme.json.
//

import Theme

enum AccountTheme {
    enum Styles {
        static let labelBase = ThemeStyleID("account.Label.Base")
        static let labelPrimary = ThemeStyleID("account.Label.Primary")
        static let labelBrand = ThemeStyleID("account.Label.Brand")
    }
}

extension SemanticStyle where Colors == CoreTheme.ColorSet {
    static var accountLabelBase: Self { .style(AccountTheme.Styles.labelBase) }
    static var accountLabelPrimary: Self { .style(AccountTheme.Styles.labelPrimary) }
    static var accountLabelBrand: Self { .style(AccountTheme.Styles.labelBrand) }
}
