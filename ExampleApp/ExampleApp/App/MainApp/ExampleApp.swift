//
//  ExampleApp.swift
//  ExampleApp
//
//  Created by Praveen Prabhakar on 03/09/22.
//

import Theme
import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await ThemeLoader.setupApplicationTheme()
                }
        }
    }
}

struct ThemeLoader {
    static let themeName = "Theme.json"
    static let accountThemeName = "AccountTheme.json"

    @MainActor
    static func setupApplicationTheme() async {
        guard let baseThemeData = try? Data.contentOfFile(themeName) else { return }
        try? await ThemesManager.setupApplicationTheme(baseThemeData)

        guard let accountThemeData = try? Data.contentOfFile(accountThemeName) else { return }
        try? await ThemesManager.register(AccountThemeProvider(themeData: accountThemeData))
    }
}
