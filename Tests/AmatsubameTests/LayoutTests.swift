@testable import Amatsubame
import AppKit
import Testing

private func textCommands(_ html: String) -> [DrawText] {
    paintTree(layoutDocument(parse(html))).compactMap { $0 as? DrawText }
}

struct LayoutTests {
    @Test func `single word near origin`() throws {
        let list = textCommands("hello")
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "hello")
        #expect(item.x == Layout.horizontalEdgeMargin)
        // Baseline pushes y below the top margin.
        #expect(item.y >= Layout.verticalEdgeMargin)
    }

    @Test func `one item per word`() {
        #expect(textCommands("hello there world").count == 3)
    }

    @Test func `long text wraps to a new line`() throws {
        let list = textCommands(String(repeating: "word ", count: 100))
        let firstY = try #require(list.first).y
        // Some later word must sit on a lower line.
        #expect(list.contains { $0.y > firstY })
        // Wrapped words restart at the left margin.
        #expect(list.contains { $0.x == Layout.horizontalEdgeMargin && $0.y > firstY })
    }

    @Test func `bold tag yields a bold font`() throws {
        let item = try #require(textCommands("<b>bold</b>").first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.boldFontMask))
    }

    @Test func `italic tag yields an italic font`() throws {
        let item = try #require(textCommands("<i>slanted</i>").first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.italicFontMask))
    }

    @Test func `big tag increases font size`() throws {
        let normal = try #require(textCommands("word").first)
        let big = try #require(textCommands("<big>word</big>").first)
        #expect(big.font.pointSize > normal.font.pointSize)
    }

    @Test func `small tag decreases font size`() throws {
        let normal = try #require(textCommands("word").first)
        let small = try #require(textCommands("<small>word</small>").first)
        #expect(small.font.pointSize < normal.font.pointSize)
    }

    @Test func `br starts a new line`() throws {
        let list = textCommands("first<br>second")
        #expect(list.count == 2)
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(second.x == Layout.horizontalEdgeMargin)
    }

    @Test func `mixed sizes share a baseline`() throws {
        // Two words on one line: larger word has a taller ascent, so its top (y)
        // sits higher (smaller y) than the smaller word's.
        let list = textCommands("<big>Big</big> small")
        let big = try #require(list.first { $0.text == "Big" })
        let small = try #require(list.first { $0.text == "small" })
        #expect(big.y < small.y)
    }

    @Test func `empty tokens produce no items`() {
        #expect(textCommands("").isEmpty)
    }

    @Test func `block elements stack vertically`() throws {
        let list = textCommands("<div><p>first</p><p>second</p></div>")
        let first = try #require(list.first { $0.text == "first" })
        let second = try #require(list.first { $0.text == "second" })
        #expect(second.y > first.y)
        #expect(first.x == second.x)
    }

    @Test func `pre element paints a background rectangle`() {
        #expect(paintTree(layoutDocument(parse("<pre>code</pre>"))).contains { $0 is DrawRect })
    }
}
