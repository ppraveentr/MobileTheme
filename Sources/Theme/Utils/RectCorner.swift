//
//  RectCorner.swift
//  Theme
//
//  Created by Praveen P on 10/9/23.
//

import Foundation
import SwiftUI

struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)

    static let allCorners: RectCorner = [.topLeft, topRight, .bottomLeft, .bottomRight]

    static func corners(_ radiusList: [CGFloat]?) -> RectCorner {
        guard let radiusList, radiusList.count == 4 else {
            return .allCorners
        }
        var corners = [RectCorner]()
        if radiusList[0] > 0.0 {
            corners.append(.topLeft)
        }
        if radiusList[1] > 0.0 {
            corners.append(.topRight)
        }
        if radiusList[2] > 0.0 {
            corners.append(.bottomLeft)
        }
        if radiusList[3] > 0.0 {
            corners.append(.bottomRight)
        }
        return RectCorner(corners)
    }
}
