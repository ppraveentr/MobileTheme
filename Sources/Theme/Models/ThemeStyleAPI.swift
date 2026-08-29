//
//  ThemeStyleAPI.swift
//  Theme
//
//  Created by Praveen Prabhakar on 11/09/22.
//

import SwiftUI

enum ThemeMode: String, Codable, Sendable {
    case light
    case dark
}

public struct ThemeStyleID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct ColorID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension ThemeStyleID {
    func appendingState(_ viewState: ViewState) -> ThemeStyleID {
        ThemeStyleID("\(rawValue)\(viewState.value)")
    }
}

public struct StyleToken: Hashable, Sendable {
    public let styleID: ThemeStyleID
    public let foregroundColorID: ColorID?

    public init(styleID: ThemeStyleID, foregroundColorID: ColorID? = nil) {
        self.styleID = styleID
        self.foregroundColorID = foregroundColorID
    }

    public init(_ styleID: ThemeStyleID, foregroundColorID: ColorID? = nil) {
        self.init(styleID: styleID, foregroundColorID: foregroundColorID)
    }

    public init(_ rawValue: String, foregroundColorID: ColorID? = nil) {
        self.init(styleID: .init(rawValue), foregroundColorID: foregroundColorID)
    }
}

public struct StyleScope: Hashable, Sendable {
    public let styleID: ThemeStyleID

    public init(styleID: ThemeStyleID) {
        self.styleID = styleID
    }

    public var style: StyleToken {
        StyleToken(styleID: styleID)
    }

    public func foreground(_ foregroundColorID: ColorID) -> StyleToken {
        StyleToken(styleID: styleID, foregroundColorID: foregroundColorID)
    }
}

@dynamicMemberLookup
public struct StyleSelectionValue: Hashable, Sendable {
    public let semanticStyle: StyleScope
    public let semanticColor: ColorID?

    public init(_ semanticStyle: StyleScope, semanticColor: ColorID? = nil) {
        self.semanticStyle = semanticStyle
        self.semanticColor = semanticColor
    }

    public func semanticColor(_ semanticColor: ColorID) -> StyleSelectionValue {
        StyleSelectionValue(semanticStyle, semanticColor: semanticColor)
    }

    public func semanticColor(_ rawValue: String) -> StyleSelectionValue {
        semanticColor(ColorID(rawValue: rawValue))
    }

    public subscript(dynamicMember semanticColorMember: String) -> StyleSelectionValue {
        semanticColor(ColorID(rawValue: semanticColorMember))
    }
}

public protocol SemanticColorSet {
    init()
}

@dynamicMemberLookup
public struct StyleSelection<Colors: SemanticColorSet> {
    public let selection: StyleSelectionValue
    private let semanticColors = Colors()

    public init(selection: StyleSelectionValue) {
        self.selection = selection
    }

    public subscript(dynamicMember keyPath: KeyPath<Colors, ColorID>) -> StyleSelectionValue {
        selection.semanticColor(semanticColors[keyPath: keyPath])
    }
}

@propertyWrapper
public struct StyleValue<Colors: SemanticColorSet>: Sendable {
    private let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init<Module: ThemeModuleProviding>(module: Module.Type, _ rawValue: String) {
        self.rawValue = Module.namespaced(rawValue)
    }

    public init(wrappedValue: StyleSelection<Colors>, _ rawValue: String) {
        self.rawValue = rawValue
    }

    public var wrappedValue: StyleSelection<Colors> {
        StyleSelection(
            selection: StyleSelectionValue(
                StyleScope(styleID: ThemeStyleID(rawValue: rawValue))
            )
        )
    }
}

@propertyWrapper
public struct ColorValue: Sendable {
    private let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init<Module: ThemeModuleProviding>(module: Module.Type, _ rawValue: String) {
        self.rawValue = Module.namespaced(rawValue)
    }

    public init(wrappedValue: ColorID, _ rawValue: String) {
        self.rawValue = rawValue
    }

    public var wrappedValue: ColorID {
        ColorID(rawValue: rawValue)
    }
}

public extension ThemeStyleID {
    subscript(_ foregroundColorID: ColorID) -> StyleToken {
        StyleToken(styleID: self, foregroundColorID: foregroundColorID)
    }

    func foreground(_ foregroundColorID: ColorID) -> StyleToken {
        StyleToken(styleID: self, foregroundColorID: foregroundColorID)
    }
}

public protocol ThemeModuleProviding {
    static var namespace: String { get }
    var themeData: Data { get }
}

public extension ThemeModuleProviding {
    var namespace: String { Self.namespace }

    static func namespaced(_ key: String) -> String {
        guard !namespace.isEmpty, !key.hasPrefix("\(namespace).") else { return key }
        return "\(namespace).\(key)"
    }
}
