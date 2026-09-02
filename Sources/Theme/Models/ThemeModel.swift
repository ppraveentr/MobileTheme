//
//  ThemeModel.swift
//  Theme
//
//  Created by Praveen Prabhakar on 11/09/22.
//

import SwiftUI

enum ThemeMergeError: LocalizedError, Equatable {
    case duplicateStyle(String)

    var errorDescription: String? {
        switch self {
        case let .duplicateStyle(styleID):
            return "Cannot override an existing style during module merge: \(styleID)."
        }
    }
}

public class ThemeModel {
    var themeId: String?
    var schemaVersion: Int?
    var colors = [String: Appearance<Color>]()
    var backgrounds = [String: StyleBackground]()
    var borders = [String: StyleBorder]()
    var fonts = [String: Font]()
    var styles = [String: UserStyle]()

    struct UserStyle {
        var forground: Appearance<Color>?
        var background: StyleBackground?
        var font: Appearance<Font>?
        var border: StyleBorder?
        var alignment: ThemeJSONModel.AlignmentModel?
    }

    struct Lookup {
        let primary: ThemeModel
        let fallback: ThemeModel?

        func color(_ key: String?) -> Appearance<Color>? {
            guard let key else { return nil }
            return primary.colors[key] ?? fallback?.colors[key]
        }

        func background(_ key: String?) -> StyleBackground? {
            guard let key else { return nil }
            return primary.backgrounds[key] ?? fallback?.backgrounds[key]
        }

        func border(_ key: String?) -> StyleBorder? {
            guard let key else { return nil }
            return primary.borders[key] ?? fallback?.borders[key]
        }

        func font(_ key: String?) -> Font? {
            guard let key else { return nil }
            return primary.fonts[key] ?? fallback?.fonts[key]
        }
    }

    public struct StyleBorder {
        var radius: [CGFloat]?
        var thickness: CGFloat?
        var color: Appearance<Color>?

        static func create(
            _ borderStyle: ThemeJSONModel.BorderModel,
            lookup: Lookup
        ) -> StyleBorder {
            let borderColor = lookup.color(borderStyle.color)
            return .init(radius: borderStyle.radius, thickness: borderStyle.thickness, color: borderColor)
        }
    }

    public struct StyleBackground {
        var color: Appearance<Color>?
        var ignoringSafeArea: Bool?
        var gradient: ThemeJSONModel.GradientModel?

        static func create(
            _ backgroundStyle: ThemeJSONModel.BackgroundModel,
            lookup: Lookup
        ) -> StyleBackground {
            let bgLight = lookup.color(backgroundStyle.color)
            return .init(
                color: bgLight,
                ignoringSafeArea: backgroundStyle.ignoringSafeArea,
                gradient: backgroundStyle.gradient
            )
        }
    }

    func merge(_ moduleModel: ThemeModel, namespace: String) throws {
        let qualifiedStyles = moduleModel.styles.reduce(into: [String: UserStyle]()) { dictionary, entry in
            dictionary[qualified(entry.key, namespace: namespace)] = entry.value
        }
        if let duplicateStyleID = qualifiedStyles.keys.sorted().first(where: { styles[$0] != nil }) {
            throw ThemeMergeError.duplicateStyle(duplicateStyleID)
        }

        moduleModel.colors.forEach { colors[qualified($0.key, namespace: namespace)] = $0.value }
        moduleModel.backgrounds.forEach { backgrounds[qualified($0.key, namespace: namespace)] = $0.value }
        moduleModel.borders.forEach { borders[qualified($0.key, namespace: namespace)] = $0.value }
        moduleModel.fonts.forEach { fonts[qualified($0.key, namespace: namespace)] = $0.value }
        qualifiedStyles.forEach { styles[$0] = $1 }
    }

    private func qualified(_ key: String, namespace: String) -> String {
        guard !namespace.isEmpty, !key.hasPrefix("\(namespace).") else { return key }
        return "\(namespace).\(key)"
    }
}

/// Generate ``ThemeModel`` based on `json Data`
extension ThemeModel {
    static func generateModel(_ jsonData: Data, mode: ThemeMode = .light, fallbackModel: ThemeModel? = nil) throws -> ThemeModel {
        let theme = try JSONDecoder().decode(ThemeJSONModel.self, from: jsonData)
        let resolver = ThemeResolver()
        let model = try resolver.resolve(theme, mode: mode, fallbackModel: fallbackModel)

        guard mode == .light, theme.semantic?[ThemeMode.dark.rawValue] != nil else {
            return model
        }

        let darkColors = try resolver.resolve(theme, mode: .dark, fallbackModel: fallbackModel).colors
        mergeDarkColors(into: model, darkColors: darkColors)
        rebuildDerivedStyles(theme: theme, model: model, fallbackModel: fallbackModel)
        return model
    }

    private static func mergeDarkColors(into model: ThemeModel, darkColors: [String: Appearance<Color>]) {
        for (key, darkColor) in darkColors {
            if var color = model.colors[key] {
                color.dark = darkColor.light
                model.colors[key] = color
                continue
            }
            model.colors[key] = darkColor
        }
    }

    private static func rebuildDerivedStyles(
        theme: ThemeJSONModel,
        model: ThemeModel,
        fallbackModel: ThemeModel?
    ) {
        let lookup = Lookup(primary: model, fallback: fallbackModel)
        model.backgrounds = (theme.backgrounds ?? [:]).reduce(into: [:]) { dictionary, entry in
            dictionary[entry.key] = StyleBackground.create(entry.value, lookup: lookup)
        }
        model.borders = (theme.borders ?? [:]).reduce(into: [:]) { dictionary, entry in
            dictionary[entry.key] = StyleBorder.create(entry.value, lookup: lookup)
        }
        model.styles = theme.flattenedStyles().reduce(into: [:]) { dictionary, entry in
            dictionary[entry.key] = style(entry.value, lookup: lookup)
        }
    }

    /// Generate ``ThemeModel/UserStyle`` based on ``ThemeStructure.UserStyle``
    static func style(
        _ style: ThemeJSONModel.UserStyleModel,
        lookup: Lookup
    ) -> UserStyle {
        let background = resolvedBackground(style.background, lookup: lookup)
        let border = resolvedBorder(style: style, lookup: lookup)
        let font = resolvedFont(style.font, lookup: lookup)
        let foreground = lookup.color(style.forgroundColor)

        return UserStyle(
            forground: foreground,
            background: background,
            font: font,
            border: border,
            alignment: style.alignment
        )
    }

    private static func resolvedBackground(
        _ background: ThemeJSONModel.StyleBackgroundReferenceModel?,
        lookup: Lookup
    ) -> StyleBackground? {
        background?.token.flatMap(lookup.background)
            ?? background?.value.map { StyleBackground.create($0, lookup: lookup) }
    }

    private static func resolvedBorder(
        style: ThemeJSONModel.UserStyleModel,
        lookup: Lookup
    ) -> StyleBorder? {
        lookup.border(style.border)
    }

    private static func resolvedFont(
        _ fontName: String?,
        lookup: Lookup
    ) -> Appearance<Font>? {
        guard let font = lookup.font(fontName) else { return nil }
        return Appearance(font, dark: nil)
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
