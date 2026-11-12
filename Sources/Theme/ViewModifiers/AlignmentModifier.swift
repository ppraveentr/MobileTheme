//
//  AlignmentModifier.swift
//  Theme
//
//  Created by Praveen P on 10/14/23.
//

import SwiftUI
import ThemeCore

struct AlignmentModifier: ViewModifier {
    var themeValue: ThemeJSONModel.AlignmentModel?

    func body(content: Content) -> some View {
        if let themeValue {
            content
                .multilineTextAlignment(themeValue.textAlignment)
        } else {
            content
        }
    }
}

extension View {
    /// Call this function to set the style for the elements by using the current body
    /// of the caller that will have the modifier applied to it.
    /// - Parameters:
    ///   - aligment: ``ThemeJSONModel.AlignmentModel`` for the element
    /// - Returns: Modified ``View`` that incorporates the view modifier.
    func theme(_ aligment: ThemeJSONModel.AlignmentModel?) -> some View {
        return modifier(AlignmentModifier(themeValue: aligment))
    }
}
