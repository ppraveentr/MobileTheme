//
//  Font+Extenstion.swift
//  
//
//  Created by Praveen Prabhakar on 22/10/22.
//

import SwiftUI

public extension Font {
    /// Generate ``Font`` based on `styleName`
    static func fromStyleName(styleName: String) -> Font? {
        switch styleName {
        case "largeTitle":
            return .largeTitle
        case "title", "title2", "title3":
            return .title
        case "headline":
            return .headline
        case "subheadline":
            return .subheadline
        case "body":
            return .body
        case "callout":
            return .callout
        case "footnote":
            return .footnote
        case "caption", "caption2":
            return .caption
        default:
            return nil
        }
    }

    /// Generate ``Font`` based on `size: CGFloat` and ``Font/Weight``
    static func fromSize(size: CGFloat, weight: String) -> Font? {
        .system(size: size, weight: weightValue(weight))
    }

    /// Generate ``Font/Weight`` based on `weight`
    static func weightValue(_ weight: String) -> Font.Weight {
        switch weight {
        case "ultraLight":
            return .ultraLight
        case "thin":
            return .thin
        case "light":
            return .light
        case "medium":
            return .medium
        case "semibold":
            return .semibold
        case "bold":
            return .bold
        case "heavy":
            return .heavy
        case "black":
            return .black
        default:
            return .regular
        }
    }
}
