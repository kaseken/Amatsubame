@testable import Amatsubame
import AppKit
import Testing

struct LayoutTests {
    @Test func `single word near origin`() throws {
        let list = layout(lex("hello"))
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "hello")
        #expect(item.x == LayoutMetrics.horizontalStep)
        // Baseline pushes y below the top margin.
        #expect(item.y >= LayoutMetrics.verticalStep)
    }

    @Test func `one item per word`() {
        #expect(layout(lex("hello there world")).count == 3)
    }

    @Test func `long text wraps to a new line`() throws {
        let list = layout(lex(String(repeating: "word ", count: 100)))
        let firstY = try #require(list.first).y
        // Some later word must sit on a lower line.
        #expect(list.contains { $0.y > firstY })
        // Wrapped words restart at the left margin.
        #expect(list.contains { $0.x == LayoutMetrics.horizontalStep && $0.y > firstY })
    }

    @Test func `bold tag yields a bold font`() throws {
        let list = layout(lex("<b>bold</b>"))
        let item = try #require(list.first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.boldFontMask))
    }

    @Test func `italic tag yields an italic font`() throws {
        let list = layout(lex("<i>slanted</i>"))
        let item = try #require(list.first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.italicFontMask))
    }

    @Test func `big tag increases font size`() throws {
        let normal = try #require(layout(lex("word")).first)
        let big = try #require(layout(lex("<big>word</big>")).first)
        #expect(big.font.pointSize > normal.font.pointSize)
    }

    @Test func `small tag decreases font size`() throws {
        let normal = try #require(layout(lex("word")).first)
        let small = try #require(layout(lex("<small>word</small>")).first)
        #expect(small.font.pointSize < normal.font.pointSize)
    }

    @Test func `br starts a new line`() throws {
        let list = layout(lex("first<br>second"))
        #expect(list.count == 2)
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(second.x == LayoutMetrics.horizontalStep)
    }

    @Test func `mixed sizes share a baseline`() throws {
        // Two words on one line: larger word has a taller ascent, so its top (y)
        // sits higher (smaller y) than the smaller word's.
        let list = layout(lex("<big>Big</big> small"))
        let big = try #require(list.first { $0.text == "Big" })
        let small = try #require(list.first { $0.text == "small" })
        #expect(big.y < small.y)
    }

    @Test func `empty tokens produce no items`() {
        #expect(layout([]).isEmpty)
    }
}
