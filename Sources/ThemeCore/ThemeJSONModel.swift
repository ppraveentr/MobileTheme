//
//  ThemeJSONStructure.swift
//  ThemeCore
//
//  Created by Praveen Prabhakar on 16/09/22.
//

import Foundation

public struct ThemeJSONModel: Codable {
    public struct FontModel: Codable {
        public var size: CGFloat?
        /// Based on ``Font/Weight``
        public var weight: String?
        /// Based on ``Font/TextStyle``
        public var styleName: String?
    }

    public struct ColorModel: Codable {
        public var light: String
        public var dark: String?
    }

    public struct UserStyleModel: Codable {
        public var forgroundColor: String?
        public var font: String?
        public var background: StyleBackgroundReferenceModel?
        public var border: String?
        public var alignment: AlignmentModel?
    }

    public indirect enum StyleNode: Codable {
        case style(UserStyleModel)
        case group([String: StyleNode])

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let group = try? container.decode([String: StyleNode].self) {
                self = .group(group)
                return
            }
            self = .style(try container.decode(UserStyleModel.self))
        }

        public func encode(to encoder: Encoder) throws {
            public var container = encoder.singleValueContainer()
            switch self {
            case let .style(style):
                try container.encode(style)
            case let .group(group):
                try container.encode(group)
            }
        }
    }

    public struct StyleBackgroundReferenceModel: Codable {
        public var token: String?
        public var value: BackgroundModel?

        init(token: String) {
            self.token = token
            self.value = nil
        }

        init(value: BackgroundModel) {
            self.token = nil
            self.value = value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let token = try? container.decode(String.self) {
                self.init(token: token)
                return
            }
            self.init(value: try container.decode(BackgroundModel.self))
        }

        public func encode(to encoder: Encoder) throws {
            public var container = encoder.singleValueContainer()
            if let token {
                try container.encode(token)
                return
            }
            if let value {
                try container.encode(value)
            }
        }
    }

    public struct BackgroundModel: Codable {
        public var color: String?
        public var ignoringSafeArea: Bool?
        public var gradient: GradientModel?
    }

    public struct GradientModel: Codable {
        public var colors: [String]
        public var locations: [CGFloat]?
    }

    public struct BorderModel: Codable {
        public var radius: [CGFloat]?
        public var thickness: CGFloat?
        public var color: String?
    }

    public enum AlignmentModel: String, Codable {
        case left, center, right
    }

    public var version: String?
    public var schemaVersion: Int?
    public var themeId: String?
    public var palettes: [String: [String: [String: String]]]?
    public var semantic: [String: [String: String]]?
    public var colors: [String: String]?
    public var backgrounds: [String: BackgroundModel]?
    public var borders: [String: BorderModel]?
    public var fonts: [String: FontModel]?
    public var styles: [String: StyleNode]?
}

public extension ThemeJSONModel {
    func flattenedStyles() -> [String: UserStyleModel] {
        flatten(nodes: styles ?? [:], parentKey: nil)
    }

    private func flatten(
        nodes: [String: StyleNode],
        parentKey: String?
    ) -> [String: UserStyleModel] {
        public var flattened = [String: UserStyleModel]()
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
