//
//  ThemeResolver.swift
//  Theme
//
//  Created by Praveen Prabhakar on 11/09/22.
//

import SwiftUI

enum ThemeResolutionError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(Int)
    case missingPalette(String)
    case missingToken(String)
    case unknownSemanticOverride(String)
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
        case let .unknownSemanticOverride(token):
            return "Semantic override references an undeclared semantic token: \(token)."
        case let .cyclicAlias(token):
            return "Theme token contains a cyclic alias: \(token)."
        case let .invalidColor(value):
            return "Invalid color value: \(value)."
        }
    }
}

protocol ThemeResolving {
    func resolve(_ payload: ThemeJSONModel, mode: ThemeMode, fallbackModel: ThemeModel?) throws -> ThemeModel
}

struct ThemeResolver: ThemeResolving {
    private let supportedSchemaVersion = 1

    func resolve(_ payload: ThemeJSONModel, mode: ThemeMode, fallbackModel: ThemeModel? = nil) throws -> ThemeModel {
        if let schemaVersion = payload.schemaVersion, schemaVersion != supportedSchemaVersion {
            throw ThemeResolutionError.unsupportedSchemaVersion(schemaVersion)
        }

        let model = ThemeModel()
        model.themeId = payload.themeId
        model.schemaVersion = payload.schemaVersion
        model.namespace = payload.namespace

        try validateSemanticOverrides(payload)
        let resolvedColors = try resolveColors(payload, mode: mode)
        resolvedColors.forEach { model.colors[$0.key] = $0.value }
        let lookup = ThemeModel.Lookup(primary: model, fallback: fallbackModel)

        payload.backgrounds?.forEach {
            model.backgrounds[$0] = ThemeModel.StyleBackground.create($1, lookup: lookup)
        }
        payload.borders?.forEach {
            model.borders[$0] = ThemeModel.StyleBorder.create($1, lookup: lookup)
        }
        payload.fonts?.forEach { model.fonts[$0] = Font.style($1) }
        payload.flattenedStyles().forEach { model.styles[$0] = ThemeModel.style($1, lookup: lookup) }
        return model
    }

    private func validateSemanticOverrides(_ payload: ThemeJSONModel) throws {
        guard let semanticOverrides = payload.semanticOverrides else { return }

        var semanticTokenNames = Set<String>()
        if let sharedSemantic = payload.semantic?.shared {
            semanticTokenNames.formUnion(sharedSemantic.keys)
        }
        payload.semantic?.modes?.values.forEach {
            semanticTokenNames.formUnion($0.keys)
        }

        for mode in semanticOverrides.keys.sorted() {
            guard let modeOverrides = semanticOverrides[mode] else { continue }
            for token in modeOverrides.keys.sorted() where !semanticTokenNames.contains(token) {
                throw ThemeResolutionError.unknownSemanticOverride(token)
            }
        }
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
            if let sharedSemantic = semantic.shared {
                tokens.merge(sharedSemantic) { _, semanticValue in semanticValue }
            } else if let modeSemantic = semantic.modes?[mode.rawValue] {
                tokens.merge(modeSemantic) { _, semanticValue in semanticValue }
            } else if semantic.modes != nil {
                throw ThemeResolutionError.missingPalette(mode.rawValue)
            }
        }

        if let modeOverrides = payload.semanticOverrides?[mode.rawValue] {
            tokens.merge(modeOverrides) { _, semanticValue in semanticValue }
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

    private func resolveToken(_ key: String, tokens: [String: String], resolving: Set<String>) throws -> String {
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
