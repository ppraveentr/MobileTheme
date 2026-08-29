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
    let foregroundColorID: ColorID?
    let viewState: ViewState

    @State private var themeStyle: ThemeModel.UserStyle?

    public func body(content: Content) -> some View {
        let resolvedStyleID = styleID.appendingState(viewState)
        let taskID = ResolvedStyleTaskID(styleID: resolvedStyleID, foregroundColorID: foregroundColorID)
        let backGroundStyle = themeStyle?.background
        return content
            .task(id: taskID) {
            themeStyle = await ThemesManager.resolvedStyle(
                styleID: resolvedStyleID,
                foregroundColorID: foregroundColorID
            )
            }
            .theme(themeStyle?.font)
            .theme(.foreground(color: themeStyle?.forground))
            .theme(.background(color: backGroundStyle?.color, ignoreSafeArea: backGroundStyle?.ignoringSafeArea))
            .theme(themeStyle?.border)
            .theme(themeStyle?.alignment)
    }
}

private struct ResolvedStyleTaskID: Hashable {
    let styleID: ThemeStyleID
    let foregroundColorID: ColorID?
}

public extension View {
    /// Applies a generated semantic style token.
    /// - Parameters:
    ///   - semanticStyleToken: Generated semantic style token.
    ///   - viewState: Optional component state suffix.
    /// - Returns: Modified ``View`` that incorporates the theme modifier.
    func style(_ semanticStyleToken: StyleToken, viewState: ViewState = .normal) -> some View {
        modifier(
            ThemeModifier(
                styleID: semanticStyleToken.styleID,
                foregroundColorID: semanticStyleToken.foregroundColorID,
                viewState: viewState
            )
        )
    }

    /// Applies a generated semantic style selection.
    /// - Parameters:
    ///   - selection: Style selection with optional semantic foreground color.
    ///   - viewState: Optional component state suffix.
    /// - Returns: Modified ``View`` that incorporates the theme modifier.
    func style(_ selection: StyleSelectionValue, viewState: ViewState = .normal) -> some View {
        style(selection.semanticStyle, semanticColor: selection.semanticColor, viewState: viewState)
    }

    /// Applies a generated semantic style selection bound to a semantic color set.
    /// - Parameters:
    ///   - selection: Style selection that can chain semantic color members.
    ///   - viewState: Optional component state suffix.
    /// - Returns: Modified ``View`` that incorporates the theme modifier.
    func style<Colors>(
        _ selection: StyleSelection<Colors>,
        viewState: ViewState = .normal
    ) -> some View where Colors: SemanticColorSet {
        style(selection.selection, viewState: viewState)
    }

    /// Applies a generated semantic style scope with optional semantic foreground override.
    /// - Parameters:
    ///   - semanticStyle: Generated semantic style scope.
    ///   - semanticColor: Optional semantic foreground color override.
    ///   - viewState: Optional component state suffix.
    /// - Returns: Modified ``View`` that incorporates the theme modifier.
    func style(_ semanticStyle: StyleScope, semanticColor: ColorID? = nil, viewState: ViewState = .normal) -> some View {
        let styleToken = semanticColor.map { semanticStyle.foreground($0) } ?? semanticStyle.style
        return style(styleToken, viewState: viewState)
    }
}
