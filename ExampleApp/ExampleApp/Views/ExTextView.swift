//
//  ExTextView.swift
//  ExampleApp
//
//  Created by Praveen Prabhakar on 17/09/22.
//

import SwiftUI
import Theme

struct ExTextView: View {
    enum Constants {
        static var themeFont: Appearance<Font> { .init(.largeTitle, dark: .headline) }
        static let rwTitleStyle = Theme.ThemeStyleID("TitleRW")
        static let brBodyStyle = Theme.ThemeStyleID("BodyBR")
    }

    @AppStorage("isLightMode") var isLightMode: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Color Scheme", isOn: $isLightMode)
                .theme(Constants.themeFont)
            Text("Font as 'title' in LightMode and 'headline' in DarkMode")
                .theme(Constants.themeFont)
            Text("Text 'Black' in LightMode and 'White' in DarkMode")
                .padding()
                .style(Constants.rwTitleStyle)
            Text("Text 'Blue' in LightMode and 'Red' in DarkMode")
                .style(Constants.brBodyStyle)
            Spacer()
        }
        .foregroundColor(.green)
        .padding(20)
        .modifier(ColorSchemeModifier(isLightMode: $isLightMode))
        .navigationTitle("Themes - Dark/Light Mode")
    }
}

// MARK: Preview

#Preview {
    ExTextView()
        .task {
            await ThemeLoader.setupApplicationTheme()
        }
}
