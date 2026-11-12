//
//  ThemesManager.swift
//  Themes
//
//  Created by Praveen Prabhakar on 03/09/22.
//

import Foundation
import SwiftUI

public actor ThemesManager {
    public static let shared = ThemesManager()

    private var themeModel: ThemeModel?
    private var styleCache = BoundedCache<ResolvedStyleCacheKey, ThemeModel.UserStyle>(capacity: 512)
    private var themeVersion: UInt64 = 0

    /// Creates an isolated manager, e.g. for another brand, window, preview or test.
    init(cacheCapacity: Int = 512) {
        styleCache = BoundedCache(capacity: cacheCapacity)
    }

/// Call this function to generate `ColorSchemeValue: ThemeModel`,
/// For `light` and `dark` style from Data dictionary ofType`ThemeDic`
///
/// - Parameters:
///   - jsonData: `ColorSchemeValue<Data>` of json  for `light` and `dark` style
    public static func setupApplicationTheme(_ jsonData: Data) async throws {
        try await shared.setup(jsonData)
    }

    /// Instance variant of ``setupApplicationTheme(_:)`` for isolated managers.
    func setup(_ jsonData: Data) throws {
        setThemeModel(try ThemeModel.generateModel(jsonData))
    }

/// Registers a module-owned theme payload into the consolidated application theme.
/// Module styles are namespaced as `moduleNamespace.styleName` during registration.
/// Generated module style IDs must use the same namespaced value.
    public static func register(_ module: ThemeModuleProviding) async throws {
        try await shared.register(namespace: module.namespace, themeData: module.themeData)
    }

    /// Composes a new model snapshot; the live model is only replaced if every step succeeds.
    func register(namespace: String, themeData: Data) throws {
        let currentModel = themeModel ?? ThemeModel()
        let moduleModel = try ThemeModel.generateModel(themeData, fallbackModel: currentModel)
        let composed = currentModel.copy()
        try composed.merge(moduleModel, namespace: namespace)
        themeModel = composed
        // Registration only adds namespaced keys, so other cached styles stay valid.
        let prefix = "\(namespace)."
        styleCache.removeAll { $0.styleID.hasPrefix(prefix) }
    }

    private func setThemeModel(_ model: ThemeModel) {
        themeVersion &+= 1
        styleCache.removeAll()
        themeModel = model
    }
}

/// Extentions to get 'ColorSchemeValue' based on style name
extension ThemesManager {
/// Call this function to get `ColorSchemeValue: Font`
///
/// - Parameters:
///   - style: Name of the style to fetch
/// - Returns: `Font`
    static func font(_ name: String) async -> Font? {
        await shared.themeModel?.fonts[name]
    }

/// Call this function to get `ColorSchemeValue: ThemeStyles`
///
/// - Parameters:
///   - styleID: Typed style identifier generated from a theme payload.
/// - Returns: User defied style: `ThemeModel.UserStyle`
    static func style(_ styleID: ThemeStyleID) async -> ThemeModel.UserStyle? {
        await shared.themeModel?.styles[styleID.rawValue]
    }

    static func color(_ semanticColorID: ColorID) async -> Appearance<Color>? {
        await shared.themeModel?.colors[semanticColorID.rawValue]
    }

    static func resolvedStyle(styleID: ThemeStyleID, foregroundColorID: ColorID?) async -> ThemeModel.UserStyle? {
        await shared.resolvedStyle(styleID: styleID, foregroundColorID: foregroundColorID)
    }

    func resolvedStyle(styleID: ThemeStyleID, foregroundColorID: ColorID?) -> ThemeModel.UserStyle? {
        let key = ResolvedStyleCacheKey(
            themeVersion: themeVersion,
            styleID: styleID.rawValue,
            foregroundColorID: foregroundColorID?.rawValue
        )
        if let cached = styleCache.value(for: key) {
            return cached
        }

        var resolvedStyle = themeModel?.styles[styleID.rawValue]
        if let foregroundColorID, let semanticForegroundColor = themeModel?.colors[foregroundColorID.rawValue] {
            resolvedStyle?.forground = semanticForegroundColor
        }

        if let resolvedStyle {
            styleCache.insert(resolvedStyle, for: key)
        }
        return resolvedStyle
    }
}

private struct ResolvedStyleCacheKey: Hashable {
    let themeVersion: UInt64
    let styleID: String
    let foregroundColorID: String?
}
