//
//  ThemeEnvironment.swift
//  Theme
//

import SwiftUI

private struct ThemesManagerKey: EnvironmentKey {
    static let defaultValue: ThemesManager = .shared
}

public extension EnvironmentValues {
    /// Manager used by `.style(...)` to resolve styles. Defaults to ``ThemesManager/shared``.
    var themesManager: ThemesManager {
        get { self[ThemesManagerKey.self] }
        set { self[ThemesManagerKey.self] = newValue }
    }
}

public extension View {
    /// Resolves styles in this view hierarchy from an isolated manager (e.g. another brand).
    func themesManager(_ manager: ThemesManager) -> some View {
        environment(\.themesManager, manager)
    }
}
