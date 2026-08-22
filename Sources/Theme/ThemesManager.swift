//
//  ThemesManager.swift
//  Themes
//
//  Created by Praveen Prabhakar on 03/09/22.
//

import Foundation
import SwiftUI

public class ThemesManager: ObservableObject {
    public static let shared = ThemesManager()
    @Published public private(set) var themeModel: ThemeModel?

    private init() { /* dummpy function */ }

/// Call this function to generate `ColorSchemeValue: ThemeModel`,
/// For `light` and `dark` style from Data dictionary ofType`ThemeDic`
///
/// - Parameters:
///   - jsonData: `ColorSchemeValue<Data>` of json  for `light` and `dark` style
    public static func setupApplicationTheme(_ jsonData: Data) throws {
        ThemesManager.shared.themeModel = try ThemeModel.generateModel(jsonData)
    }

/// Registers a module-owned theme payload into the consolidated application theme.
/// Module styles are namespaced as `moduleNamespace.styleName` during registration.
/// Generated module style IDs must use the same namespaced value.
    public static func register(_ module: ThemeModuleProviding) throws {
        let moduleModel = try ThemeModel.generateModel(module.themeData)
        let currentModel = ThemesManager.shared.themeModel ?? ThemeModel()
        currentModel.merge(moduleModel, namespace: module.namespace)
        ThemesManager.shared.themeModel = currentModel
    }
}

/// Extentions to get 'ColorSchemeValue' based on style name
extension ThemesManager {
/// Call this function to get `ColorSchemeValue: Font`
///
/// - Parameters:
///   - style: Name of the style to fetch
/// - Returns: `Font`
    static func font(_ name: String) -> Font? {
        Self.shared.themeModel?.fonts[name]
    }

/// Call this function to get `ColorSchemeValue: ThemeStyles`
///
/// - Parameters:
///   - styleID: Typed style identifier generated from a theme payload.
/// - Returns: User defied style: `ThemeModel.UserStyle`
    static func style(_ styleID: ThemeStyleID) -> ThemeModel.UserStyle? {
        Self.shared.themeModel?.styles[styleID.rawValue]
    }
}
