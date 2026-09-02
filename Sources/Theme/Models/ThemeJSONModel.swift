//
//  ThemeJSONStructure.swift
//  Theme
//
//  Created by Praveen Prabhakar on 16/09/22.
//

import Foundation
import SwiftUI

struct ThemeJSONModel: Codable {
    struct FontModel: Codable {
        var size: CGFloat?
        /// Based on ``Font/Weight``
        var weight: String?
        /// Based on ``Font/TextStyle``
        var styleName: String?
    }

    struct ColorModel: Codable {
        var light: String
        var dark: String?
    }

    struct UserStyleModel: Codable {
        var forgroundColor: String?
        var font: String?
        var background: StyleBackgroundReferenceModel?
        var border: String?
        var alignment: AlignmentModel?
    }

    indirect enum StyleNode: Codable {
        case style(UserStyleModel)
        case group([String: StyleNode])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let group = try? container.decode([String: StyleNode].self) {
                self = .group(group)
                return
            }
            self = .style(try container.decode(UserStyleModel.self))
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .style(style):
                try container.encode(style)
            case let .group(group):
                try container.encode(group)
            }
        }
    }

    struct StyleBackgroundReferenceModel: Codable {
        var token: String?
        var value: BackgroundModel?

        init(token: String) {
            self.token = token
            self.value = nil
        }

        init(value: BackgroundModel) {
            self.token = nil
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let token = try? container.decode(String.self) {
                self.init(token: token)
                return
            }
            self.init(value: try container.decode(BackgroundModel.self))
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            if let token {
                try container.encode(token)
                return
            }
            if let value {
                try container.encode(value)
            }
        }
    }

    struct BackgroundModel: Codable {
        var color: String?
        var ignoringSafeArea: Bool?
        var gradient: GradientModel?
    }

    struct GradientModel: Codable {
        var colors: [String]
        var locations: [CGFloat]?
    }

    struct BorderModel: Codable {
        var radius: [CGFloat]?
        var thickness: CGFloat?
        var color: String?
    }

    enum AlignmentModel: String, Codable {
        case left, center, right

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

    var version: String?
    var schemaVersion: Int?
    var themeId: String?
    var palettes: [String: [String: [String: String]]]?
    var semantic: [String: [String: String]]?
    var colors: [String: String]?
    var backgrounds: [String: BackgroundModel]?
    var borders: [String: BorderModel]?
    var fonts: [String: FontModel]?
    var styles: [String: StyleNode]?
}

extension ThemeJSONModel {
    func flattenedStyles() -> [String: UserStyleModel] {
        flatten(nodes: styles ?? [:], parentKey: nil)
    }

    private func flatten(
        nodes: [String: StyleNode],
        parentKey: String?
    ) -> [String: UserStyleModel] {
        var flattened = [String: UserStyleModel]()
        for (key, node) in nodes {
            let composedKey = parentKey.map { "\($0).\(key)" } ?? key
            switch node {
            case let .style(style):
                flattened[composedKey] = style
            case let .group(children):
                let childStyles = flatten(nodes: children, parentKey: composedKey)
                childStyles.forEach { flattened[$0.key] = $0.value }
            }
        }
        return flattened
    }
}
