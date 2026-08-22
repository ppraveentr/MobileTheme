//
//  ExampleThemeStyles.generated.swift
//  ExampleApp
//
//  Generated from Resources/Theme.json.
//

import Foundation
import Theme

struct ExampleThemeStyles {
    static let titleRW = Theme.ThemeStyleID(rawValue: "TitleRW")
    static let bodyBR = Theme.ThemeStyleID(rawValue: "BodyBR")
}

struct ExampleThemeProvider: Theme.ThemeModuleProviding {
    let namespace = ""
    let themeData: Data
}
