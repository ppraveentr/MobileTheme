//
//  ThemeModifier.swift
//  Theme
//
//  Created by Praveen Prabhakar on 11/09/22.
//

import SwiftUI

/// A modifier that applies a resolved theme style from the consolidated theme registry.
public struct ThemeModifier: ViewModifier {
    let styleID: ThemeStyleID
    let viewState: ViewState

    @State private var themeStyle: ThemeModel.UserStyle?

    public func body(content: Content) -> some View {
        let resolvedStyleID = styleID.appendingState(viewState)
        DispatchQueue.main.async {
            themeStyle = ThemesManager.style(resolvedStyleID)
        }
        let backGroundStyle = themeStyle?.background
        return content
            .theme(themeStyle?.font)
            .theme(.foreground(color: themeStyle?.forground))
            .theme(.background(color: backGroundStyle?.color, ignoreSafeArea: backGroundStyle?.ignoringSafeArea))
            .theme(themeStyle?.border)
            .theme(themeStyle?.alignment)
    }
}

public extension View {
/// Applies a generated typed style identifier from the consolidated theme registry.
/// - Parameters:
///   - styleID: Generated style identifier for the element.
///   - viewState: Optional component state suffix.
/// - Returns: Modified ``View`` that incorporates the theme modifier.
    func style(_ styleID: ThemeStyleID, viewState: ViewState = .normal) -> some View {
        modifier(ThemeModifier(styleID: styleID, viewState: viewState))
    }
}
