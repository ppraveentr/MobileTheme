//
//  ExTextView.swift
//  ExampleApp
//
//  Created by Praveen Prabhakar on 17/09/22.
//

import SwiftUI
import Theme

struct ExTextView: View {
    @AppStorage("isLightMode") var isLightMode: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Color Scheme", isOn: $isLightMode)
                .style(ExampleTheme.SemanticStyle.labelBase)
            Text("Font from theme style 'Label.Base'")
                .style(ExampleTheme.SemanticStyle.labelBase)
            Text("Text 'Black' in LightMode and 'White' in DarkMode")
                .padding()
                .style(ExampleTheme.SemanticStyle.labelPrimary.textNeutral)
            Text("Text 'Blue' in LightMode and 'Red' in DarkMode")
                .style(ExampleTheme.SemanticStyle.labelBrand.textBrand)
            Divider()
            Text("Namespace example: account")
                .style(AccountTheme.SemanticStyle.labelBase)
            Text("Same style resolved from account namespace")
                .padding()
                .style(AccountTheme.SemanticStyle.labelPrimary.textNeutral)
            Text("Brand color resolved from account namespace")
                .style(AccountTheme.SemanticStyle.labelBrand.textBrand)
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
