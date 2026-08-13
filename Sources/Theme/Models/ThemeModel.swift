//
//  ThemeModel.swift
//  Theme
//
//  Created by Praveen Prabhakar on 11/09/22.
//

import SwiftUI

public enum ThemeMode: String, Codable, Sendable {
    case light
    case dark
}

enum ThemeResolutionError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(Int)
    case missingPalette(String)
    case missingToken(String)
    case cyclicAlias(String)
    case invalidColor(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported theme schema version: \(version)."
        case let .missingPalette(mode):
            return "Missing palette for theme mode: \(mode)."
        case let .missingToken(token):
            return "Missing theme token: \(token)."
        case let .cyclicAlias(token):
            return "Theme token contains a cyclic alias: \(token)."
        case let .invalidColor(value):
            return "Invalid color value: \(value)."
        }
    }
}

protocol ThemeResolving {
    func resolve(_ payload: ThemeJSONModel, mode: ThemeMode) throws -> ThemeModel
}

struct ThemeResolver: ThemeResolving {
    private let supportedSchemaVersion = 1

    func resolve(_ payload: ThemeJSONModel, mode: ThemeMode) throws -> ThemeModel {
        if let schemaVersion = payload.schemaVersion, schemaVersion != supportedSchemaVersion {
            throw ThemeResolutionError.unsupportedSchemaVersion(schemaVersion)
        }

        let model = ThemeModel()
        model.themeId = payload.themeId
        model.schemaVersion = payload.schemaVersion

        let resolvedColors = try resolveColors(payload, mode: mode)
        resolvedColors.forEach { model.colors[$0.key] = $0.value }

        payload.fonts?.forEach { model.fonts[$0] = Font.style($1) }
        payload.styles?.forEach { model.styles[$0] = ThemeModel.style($1, model: model) }
        return model
    }

    private func resolveColors(_ payload: ThemeJSONModel, mode: ThemeMode) throws -> [String: Appearance<Color>] {
        var tokens = payload.colors ?? [:]

        if let palettes = payload.palettes {
            guard let modePalette = palettes[mode.rawValue] else {
                throw ThemeResolutionError.missingPalette(mode.rawValue)
            }
            for (paletteName, scale) in modePalette {
                for (step, value) in scale {
                    tokens["palette.\(paletteName).\(step)"] = value
                }
            }
        }

        if let semantic = payload.semantic {
            guard let modeSemantic = semantic[mode.rawValue] else {
                throw ThemeResolutionError.missingPalette(mode.rawValue)
            }
            modeSemantic.forEach { tokens[$0] = $1 }
        }

        var resolvedHexValues = [String: String]()
        for key in tokens.keys {
            resolvedHexValues[key] = try resolveToken(key, tokens: tokens, resolving: [])
        }

        var resolvedColors = [String: Appearance<Color>]()
        for (key, value) in resolvedHexValues {
            guard let color = Color.style(value) else {
                throw ThemeResolutionError.invalidColor(value)
            }
            resolvedColors[key] = color
        }
        return resolvedColors
    }

    private func resolveToken(
        _ key: String,
        tokens: [String: String],
        resolving: Set<String>
    ) throws -> String {
        guard let value = tokens[key] else {
            throw ThemeResolutionError.missingToken(key)
        }

        guard let alias = Self.aliasName(from: value) else {
            return value
        }

        guard !resolving.contains(alias) else {
            throw ThemeResolutionError.cyclicAlias(alias)
        }

        var nextResolving = resolving
        nextResolving.insert(key)
        return try resolveToken(alias, tokens: tokens, resolving: nextResolving)
    }

    private static func aliasName(from value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.hasPrefix("{"), trimmedValue.hasSuffix("}") else {
            return nil
        }
        return String(trimmedValue.dropFirst().dropLast())
    }
}

public class ThemeModel {
    var themeId: String?
    var schemaVersion: Int?
    var colors = [String: Appearance<Color>]()
    var fonts = [String: Font]()
    var styles = [String: UserStyle]()

    struct UserStyle {
        var forground: Appearance<Color>?
        var background: StyleBackground?
        var font: Appearance<Font>?
        var border: StyleBorder?
        var alignment: ThemeJSONModel.AlignmentModel?
    }

    public struct StyleBorder {
        var radius: [CGFloat]?
        var thickness: CGFloat?
        var color: Appearance<Color>?

        static func create(_ borderStyle: ThemeJSONModel.BorderModel, model: ThemeModel) -> StyleBorder {
            let borderColor = model.colors[borderStyle.color ?? ""]
            return .init(radius: borderStyle.radius, thickness: borderStyle.thickness, color: borderColor)
        }
    }

    public struct StyleBackground {
        var color: Appearance<Color>?
        var ignoringSafeArea: Bool?
        var gradient: ThemeJSONModel.GradientModel?

        static func create(_ style: ThemeJSONModel.UserStyleModel, model: ThemeModel) -> StyleBackground {
            let bgLight = model.colors[style.background?.color ?? ""]
            return .init(
                color: bgLight,
                ignoringSafeArea: style.background?.ignoringSafeArea,
                gradient: style.background?.gradient
            )
        }
    }
}

/// Generate ``ThemeModel`` based on `json Data`
extension ThemeModel {
    static func generateModel(_ jsonData: Data, mode: ThemeMode = .light) throws -> ThemeModel {
        let theme = try JSONDecoder().decode(ThemeJSONModel.self, from: jsonData)
        let resolver = ThemeResolver()
        let model = try resolver.resolve(theme, mode: mode)

        guard theme.semantic?[ThemeMode.dark.rawValue] != nil, mode == .light else {
            return model
        }

        let darkModel = try resolver.resolve(theme, mode: .dark)
        for (key, darkColor) in darkModel.colors {
            if var color = model.colors[key] {
                color.dark = darkColor.light
                model.colors[key] = color
            } else {
                model.colors[key] = darkColor
            }
        }

        model.styles.removeAll()
        theme.styles?.forEach { model.styles[$0] = Self.style($1, model: model) }
        return model
    }

    /// Generate ``ThemeModel/UserStyle`` based on ``ThemeStructure.UserStyle``
    fileprivate static
    func style(_ style: ThemeJSONModel.UserStyleModel, model: ThemeModel) -> UserStyle? {
            // Colors
        let fgColor = model.colors[style.forgroundColor ?? ""]
            // StyleBackground
        let styleBackground = StyleBackground.create(style, model: model)
            // User Style Setup
        var userStyleValue = UserStyle(forground: fgColor, background: styleBackground)
        userStyleValue.alignment = style.alignment
            // StyleBorder
        if let border = style.background?.border {
            userStyleValue.border = StyleBorder.create(border, model: model)
        }
            // Fonts
        if let font = model.fonts[style.font ?? ""] {
            userStyleValue.font = Appearance(font, dark: nil)
        }
        return userStyleValue
    }
}

/// Generate ``Font`` based on ``ThemeStructure.FontStyle``
extension Font {
    static func style(_ style: ThemeJSONModel.FontModel) -> Font? {
            /// Generate ``Font`` based on StyleName ``Font/TextStyle``
        if let styleName = style.styleName,
            let font = Font.fromStyleName(styleName: styleName) {
            return font
        }
            /// Generate ``Font`` based on ``Size: CGFloat`` and ``Font/Weight``
        if let size = style.size, let weight = style.weight {
            return .fromSize(size: size, weight: weight)
        }
        return nil
    }
}

/// Generate ``Color`` based on `hex color`
extension Color {
    static func style(_ name: String) -> Appearance<Color>? {
        guard name.hasPrefix("#") else { return nil }
        let colorNames = name.components(separatedBy: ",,")
        guard let light = colorNames.first else {
            return nil
        }
        var colors = Appearance<Color>(Color(hex: light))
        if colorNames.count > 1, let dark = colorNames.last {
            colors.dark = Color(hex: dark)
        }
        return colors
    }
}
