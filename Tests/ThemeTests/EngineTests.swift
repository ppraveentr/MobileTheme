//
//  EngineTests.swift
//  UnitTest
//

import XCTest
@testable import Theme

final class BoundedCacheTests: XCTestCase {
    func testEvictsLeastRecentlyUsed() {
        var cache = BoundedCache<String, Int>(capacity: 2)
        cache.insert(1, for: "a")
        cache.insert(2, for: "b")
        _ = cache.value(for: "a")
        cache.insert(3, for: "c")
        XCTAssertEqual(cache.count, 2)
        XCTAssertNil(cache.value(for: "b"))
        XCTAssertEqual(cache.value(for: "a"), 1)
    }

    func testRemoveWhere() {
        var cache = BoundedCache<String, Int>(capacity: 4)
        cache.insert(1, for: "account.x")
        cache.insert(2, for: "base")
        cache.removeAll { $0.hasPrefix("account.") }
        XCTAssertNil(cache.value(for: "account.x"))
        XCTAssertEqual(cache.value(for: "base"), 2)
    }
}

final class IsolatedManagerTests: XCTestCase {
    private let base = Data("""
    {"fonts":{"title":{"styleName":"title"}},"styles":{"Label":{"font":"title"}}}
    """.utf8)
    private let module = Data(#"{"styles":{"Card":{"font":"title"}}}"#.utf8)

    func testManagersAreIsolated() async throws {
        let first = ThemesManager()
        let second = ThemesManager()
        try await first.setup(base)
        let inFirst = await first.resolvedStyle(styleID: "Label", foregroundColorID: nil)
        let inSecond = await second.resolvedStyle(styleID: "Label", foregroundColorID: nil)
        XCTAssertNotNil(inFirst)
        XCTAssertNil(inSecond)
    }

    func testFailedRegisterLeavesThemeUntouched() async throws {
        let manager = ThemesManager()
        try await manager.setup(base)
        try await manager.register(namespace: "account", themeData: module)
        XCTAssertNotNil(await manager.resolvedStyle(styleID: "account.Card", foregroundColorID: nil))

        do {
            try await manager.register(namespace: "account", themeData: module)
            XCTFail("expected duplicate style error")
        } catch {
            XCTAssertEqual(error as? ThemeMergeError, .duplicateStyle("account.Card"))
        }
        XCTAssertNotNil(await manager.resolvedStyle(styleID: "Label", foregroundColorID: nil))
        XCTAssertNotNil(await manager.resolvedStyle(styleID: "account.Card", foregroundColorID: nil))
    }
}
