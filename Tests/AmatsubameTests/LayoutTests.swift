@testable import Amatsubame
import AppKit
import Testing

struct LayoutTests {
    @Test func `single word near origin`() throws {
        let list = Layout(lex("hello")).displayList
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "hello")
        #expect(item.x == Layout.horizontalEdgeMargin)
        // Baseline pushes y below the top margin.
        #expect(item.y >= Layout.verticalEdgeMargin)
    }

    @Test func `one item per word`() {
        #expect(Layout(lex("hello there world")).displayList.count == 3)
    }

    @Test func `long text wraps to a new line`() throws {
        let list = Layout(lex(String(repeating: "word ", count: 100))).displayList
        let firstY = try #require(list.first).y
        // Some later word must sit on a lower line.
        #expect(list.contains { $0.y > firstY })
        // Wrapped words restart at the left margin.
        #expect(list.contains { $0.x == Layout.horizontalEdgeMargin && $0.y > firstY })
    }

    @Test func `bold tag yields a bold font`() throws {
        let list = Layout(lex("<b>bold</b>")).displayList
        let item = try #require(list.first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.boldFontMask))
    }

    @Test func `italic tag yields an italic font`() throws {
        let list = Layout(lex("<i>slanted</i>")).displayList
        let item = try #require(list.first)
        #expect(NSFontManager.shared.traits(of: item.font).contains(.italicFontMask))
    }

    @Test func `big tag increases font size`() throws {
        let normal = try #require(Layout(lex("word")).displayList.first)
        let big = try #require(Layout(lex("<big>word</big>")).displayList.first)
        #expect(big.font.pointSize > normal.font.pointSize)
    }

    @Test func `small tag decreases font size`() throws {
        let normal = try #require(Layout(lex("word")).displayList.first)
        let small = try #require(Layout(lex("<small>word</small>")).displayList.first)
        #expect(small.font.pointSize < normal.font.pointSize)
    }

    @Test func `br starts a new line`() throws {
        let list = Layout(lex("first<br>second")).displayList
        #expect(list.count == 2)
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(second.x == Layout.horizontalEdgeMargin)
    }

    @Test func `mixed sizes share a baseline`() throws {
        // Two words on one line: larger word has a taller ascent, so its top (y)
        // sits higher (smaller y) than the smaller word's.
        let list = Layout(lex("<big>Big</big> small")).displayList
        let big = try #require(list.first { $0.text == "Big" })
        let small = try #require(list.first { $0.text == "small" })
        #expect(big.y < small.y)
    }

    @Test func `empty tokens produce no items`() {
        #expect(Layout([]).displayList.isEmpty)
    }
}
