//
//  ThemeAlignment+Extension.swift
//  Theme
//

import SwiftUI
import ThemeCore

extension ThemeJSONModel.AlignmentModel {
    var textAlignment: TextAlignment {
        switch self {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }
}
