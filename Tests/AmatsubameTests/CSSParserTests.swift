@testable import Amatsubame
import Testing

struct CSSParserTests {
    @Test func `parses a single rule`() throws {
        let rules = CSSParser("p { color: red; }").parse()
        #expect(rules.count == 1)
        let rule = try #require(rules.first)
        #expect(rule.declarations["color"] == "red")
        #expect((rule.selector as? TagSelector)?.tag == "p")
    }

    @Test func `body parses multiple declarations`() {
        let declarations = CSSParser("color: red; font-weight: bold").body()
        #expect(declarations["color"] == "red")
        #expect(declarations["font-weight"] == "bold")
    }

    @Test func `pair lowercases property and value`() {
        #expect(CSSParser("Color: RED").body()["color"] == "red")
    }

    @Test func `recovers from a malformed declaration`() {
        let declarations = CSSParser("color; font-weight: bold").body()
        #expect(declarations["color"] == nil)
        #expect(declarations["font-weight"] == "bold")
    }

    @Test func `skips a malformed rule and keeps the next`() throws {
        let rules = CSSParser("p { { color: red; } a { color: blue; }").parse()
        let anchorRule = try #require(rules.first { ($0.selector as? TagSelector)?.tag == "a" })
        #expect(anchorRule.declarations["color"] == "blue")
    }

    @Test func `parses the style attribute body`() {
        let declarations = CSSParser("margin:0;color:blue").body()
        #expect(declarations["color"] == "blue")
    }
}
