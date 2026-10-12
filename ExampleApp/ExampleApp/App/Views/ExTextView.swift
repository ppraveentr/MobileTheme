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
                .style(CoreTheme.Styles.labelBase)
            Text("Font from theme style 'Label.Base'")
                .style(CoreTheme.Styles.labelBase)
            Text("Text 'Black' in LightMode and 'White' in DarkMode")
                .padding()
                .style(CoreTheme.Styles.labelPrimary[CoreTheme.Colors.textNeutral])
            Text("Text 'Blue' in LightMode and 'Red' in DarkMode")
                .style(CoreTheme.Styles.labelBrand[CoreTheme.Colors.textBrand])
            Divider()
            Text("Namespace example: account")
                .style(AccountTheme.Styles.labelBase)
            Text("Same style resolved from account namespace")
                .padding()
                .style(AccountTheme.Styles.labelPrimary[CoreTheme.Colors.textNeutral])
            Text("Brand color resolved from account namespace")
                .style(AccountTheme.Styles.labelBrand[CoreTheme.Colors.textBrand])
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
