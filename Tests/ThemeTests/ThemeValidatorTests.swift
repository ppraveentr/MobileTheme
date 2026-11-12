//
//  ThemeValidatorTests.swift
//  UnitTest
//

import XCTest
@testable import Theme

final class ThemeValidatorTests: XCTestCase {
    private func payload(_ json: String) throws -> ThemeJSONModel {
        try JSONDecoder().decode(ThemeJSONModel.self, from: Data(json.utf8))
    }

    func testValidThemeHasNoIssues() throws {
        let theme = try payload("""
        {"semantic":{"light":{"text":"#000000"},"dark":{"text":"#FFFFFF"}},
         "fonts":{"title":{"styleName":"title"}},
         "styles":{"Label":{"Base":{"font":"title","forgroundColor":"text"}}}}
        """)
        XCTAssertEqual(ThemeValidator().validate(theme), [])
    }

    func testReportsAllProblemsAtOnce() throws {
        let theme = try payload("""
        {"semantic":{"light":{"a":"{b}","b":"{a}","onlyLight":"#000000"},"dark":{"a":"#111111","b":"#222222"}},
         "styles":{"Label":{"Base":{"font":"missing","border":"nope"}}}}
        """)
        let kinds = Set(ThemeValidator().validate(theme).map(\.kind))
        XCTAssertEqual(kinds, [.cyclicAlias, .modeMismatch, .missingToken])
    }

    func testExternalTokensSatisfyModuleReferences() throws {
        let theme = try payload(#"{"styles":{"Card":{"font":"baseTitle"}}}"#)
        XCTAssertFalse(ThemeValidator().validate(theme).isEmpty)

        var external = ThemeValidator.ExternalTokens()
        external.fonts = ["baseTitle"]
        XCTAssertEqual(ThemeValidator().validate(theme, external: external), [])
    }
}
