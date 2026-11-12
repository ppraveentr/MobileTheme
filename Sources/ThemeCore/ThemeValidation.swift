//
//  ThemeValidation.swift
//  ThemeCore
//

import Foundation

/// Public entry point for statically validating theme JSON (used by `theme-cli` and CI).
public enum ThemeValidation {
    /// Validates a theme payload and returns human-readable issues (empty means valid).
    /// - Parameters:
    ///   - themeData: Theme JSON to validate.
    ///   - baseData: Optional base theme; its tokens may be referenced by `themeData` (module use case).
    public static func validate(_ themeData: Data, base baseData: Data? = nil) throws -> [String] {
        let decoder = JSONDecoder()
        let payload = try decoder.decode(ThemeJSONModel.self, from: themeData)
        let validator = ThemeValidator()
        var external = ThemeValidator.ExternalTokens()
        if let baseData {
            external = validator.publishedTokens(of: try decoder.decode(ThemeJSONModel.self, from: baseData))
        }
        return validator.validate(payload, external: external).map(\.description)
    }
}
