//
//  ThemeValidator.swift
//  Theme
//

import Foundation

/// A single problem found while statically validating a theme payload.
struct ThemeValidationIssue: Equatable, CustomStringConvertible {
    enum Kind: String {
        case missingToken
        case cyclicAlias
        case missingMode
        case modeMismatch
    }

    let kind: Kind
    /// Where the problem was found, e.g. `styles.Label.Primary.font`.
    let location: String
    let message: String

    var description: String { "[\(kind.rawValue)] \(location): \(message)" }
}

/// Statically validates a theme payload and reports *all* problems at once,
/// so CI/build tooling can fail early instead of at first runtime lookup.
struct ThemeValidator {
    /// Token names a module may reference but does not define itself
    /// (published base/semantic tokens), keyed by kind.
    struct ExternalTokens {
        var colors = Set<String>()
        var backgrounds = Set<String>()
        var borders = Set<String>()
        var fonts = Set<String>()
        init() {}
    }

    private let modes = ThemeMode.allCases.map(\.rawValue)

    func validate(_ payload: ThemeJSONModel, external: ExternalTokens = .init()) -> [ThemeValidationIssue] {
        var issues = [ThemeValidationIssue]()
        let colorTokensByMode = collectColorTokens(payload, issues: &issues)

        var knownColors = external.colors
        colorTokensByMode.values.forEach { knownColors.formUnion($0.keys) }

        for (mode, tokens) in colorTokensByMode {
            issues += aliasIssues(tokens, mode: mode, known: knownColors)
        }
        issues += modeParityIssues(colorTokensByMode)
        issues += referenceIssues(payload, knownColors: knownColors, external: external)
        return issues.sorted { $0.description < $1.description }
    }

    private func collectColorTokens(
        _ payload: ThemeJSONModel,
        issues: inout [ThemeValidationIssue]
    ) -> [String: [String: String]] {
        var result = [String: [String: String]]()
        for mode in modes {
            var tokens = payload.colors ?? [:]
            if let palettes = payload.palettes {
                if let modePalette = palettes[mode] {
                    for (name, scale) in modePalette {
                        for (step, value) in scale { tokens["palette.\(name).\(step)"] = value }
                    }
                } else {
                    issues.append(.init(kind: .missingMode, location: "palettes", message: "No palette for mode '\(mode)'."))
                }
            }
            if let semantic = payload.semantic {
                if let modeSemantic = semantic[mode] {
                    modeSemantic.forEach { tokens[$0] = $1 }
                } else {
                    issues.append(.init(kind: .missingMode, location: "semantic", message: "No semantic set for mode '\(mode)'."))
                }
            }
            result[mode] = tokens
        }
        return result
    }

    private func aliasIssues(_ tokens: [String: String], mode: String, known: Set<String>) -> [ThemeValidationIssue] {
        var issues = [ThemeValidationIssue]()
        for (key, value) in tokens {
            var seen: Set<String> = [key]
            var current = value
            while let alias = Self.aliasName(from: current) {
                if seen.contains(alias) {
                    issues.append(.init(kind: .cyclicAlias, location: "\(mode).\(key)", message: "Alias cycle through '\(alias)'."))
                    break
                }
                seen.insert(alias)
                guard let next = tokens[alias] else {
                    if !known.contains(alias) {
                        issues.append(.init(kind: .missingToken, location: "\(mode).\(key)", message: "Unknown alias '{\(alias)}'."))
                    }
                    break
                }
                current = next
            }
        }
        return issues
    }

    private func modeParityIssues(_ byMode: [String: [String: String]]) -> [ThemeValidationIssue] {
        let allKeys = Set(byMode.values.flatMap(\.keys))
        var issues = [ThemeValidationIssue]()
        for mode in byMode.keys {
            for key in allKeys.subtracting(byMode[mode]?.keys ?? [:].keys) {
                issues.append(.init(kind: .modeMismatch, location: key, message: "Token is not defined for mode '\(mode)'."))
            }
        }
        return issues
    }

    private func referenceIssues(
        _ payload: ThemeJSONModel,
        knownColors: Set<String>,
        external: ExternalTokens
    ) -> [ThemeValidationIssue] {
        var issues = [ThemeValidationIssue]()
        let backgrounds = Set(payload.backgrounds?.keys ?? [:].keys).union(external.backgrounds)
        let borders = Set(payload.borders?.keys ?? [:].keys).union(external.borders)
        let fonts = Set(payload.fonts?.keys ?? [:].keys).union(external.fonts)

        func check(_ name: String?, in set: Set<String>, kind: String, at location: String) {
            guard let name, !set.contains(name) else { return }
            issues.append(.init(kind: .missingToken, location: location, message: "Unknown \(kind) token '\(name)'."))
        }

        for (key, background) in payload.backgrounds ?? [:] {
            check(background.color, in: knownColors, kind: "color", at: "backgrounds.\(key).color")
            background.gradient?.colors.forEach {
                check($0, in: knownColors, kind: "color", at: "backgrounds.\(key).gradient")
            }
        }
        for (key, border) in payload.borders ?? [:] {
            check(border.color, in: knownColors, kind: "color", at: "borders.\(key).color")
        }
        for (key, style) in payload.flattenedStyles() {
            let base = "styles.\(key)"
            check(style.forgroundColor, in: knownColors, kind: "color", at: "\(base).forgroundColor")
            check(style.font, in: fonts, kind: "font", at: "\(base).font")
            check(style.border, in: borders, kind: "border", at: "\(base).border")
            check(style.background?.token, in: backgrounds, kind: "background", at: "\(base).background")
            check(style.background?.value?.color, in: knownColors, kind: "color", at: "\(base).background.color")
        }
        return issues
    }

    private static func aliasName(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else { return nil }
        return String(trimmed.dropFirst().dropLast())
    }
}
