@testable import Amatsubame
import AppKit
import Testing

struct LayoutTests {
    @Test func `single word near origin`() throws {
        let list = try displayCommands(for: style(parse("hello"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "hello")
        #expect(item.x == Layout.horizontalEdgeMargin)
        // Baseline pushes y below the top margin.
        #expect(item.y >= Layout.verticalEdgeMargin)
    }

    @Test func `one item per word`() throws {
        let list = try displayCommands(for: style(parse("hello there world"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["hello", "there", "world"])
    }

    @Test func `long text wraps to a new line`() throws {
        let list = try displayCommands(
            for: style(parse(String(repeating: "word ", count: 100)), rules: sortedByCascade(defaultStyleRules)),
        )
        .map { try #require($0 as? DrawText) }
        #expect(list.count == 100)
        #expect(list.allSatisfy { $0.text == "word" })
        let firstY = try #require(list.first).y
        // Some later word must sit on a lower line, restarting at the left margin.
        #expect(list.contains { $0.y > firstY })
        #expect(list.contains { $0.x == Layout.horizontalEdgeMargin && $0.y > firstY })
    }

    @Test func `bold tag yields a bold font`() throws {
        let list = try displayCommands(for: style(parse("<b>bold</b>"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "bold")
        #expect(NSFontManager.shared.traits(of: item.font).contains(.boldFontMask))
    }

    @Test func `italic tag yields an italic font`() throws {
        let list = try displayCommands(for: style(parse("<i>slanted</i>"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "slanted")
        #expect(NSFontManager.shared.traits(of: item.font).contains(.italicFontMask))
    }

    @Test func `big tag increases font size`() throws {
        let normalList = try displayCommands(for: style(parse("word"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        let bigList = try displayCommands(for: style(parse("<big>word</big>"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(normalList.count == 1)
        #expect(bigList.count == 1)
        let normal = try #require(normalList.first)
        let big = try #require(bigList.first)
        #expect(big.font.pointSize > normal.font.pointSize)
    }

    @Test func `small tag decreases font size`() throws {
        let normalList = try displayCommands(for: style(parse("word"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        let smallList = try displayCommands(for: style(parse("<small>word</small>"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(normalList.count == 1)
        #expect(smallList.count == 1)
        let normal = try #require(normalList.first)
        let small = try #require(smallList.first)
        #expect(small.font.pointSize < normal.font.pointSize)
    }

    @Test func `br starts a new line`() throws {
        let list = try displayCommands(for: style(parse("first<br>second"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["first", "second"])
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(second.x == Layout.horizontalEdgeMargin)
    }

    @Test func `mixed sizes share a baseline`() throws {
        // Two words on one line: larger word has a taller ascent, so its top (y)
        // sits higher (smaller y) than the smaller word's.
        let list = try displayCommands(for: style(parse("<big>Big</big> small"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["Big", "small"])
        let big = try #require(list.first)
        let small = try #require(list.last)
        #expect(big.y < small.y)
    }

    @Test func `empty tokens produce no items`() throws {
        let list = try displayCommands(for: style(parse(""), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.isEmpty)
    }

    @Test func `block elements stack vertically`() throws {
        let list = try displayCommands(
            for: style(parse("<div><p>first</p><p>second</p></div>"), rules: sortedByCascade(defaultStyleRules)),
        )
        .map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["first", "second"])
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(first.x == second.x)
    }

    @Test func `pre element paints a background rectangle`() throws {
        let commands = displayCommands(for: style(parse("<pre>code</pre>"), rules: sortedByCascade(defaultStyleRules)))
        #expect(commands.count == 2)
        let rect = try #require(commands.first as? DrawRect)
        #expect(rect.color == namedColor("gray"))
        let text = try #require(commands.last as? DrawText)
        #expect(text.text == "code")
    }

    @Test func `anchor text is blue`() throws {
        let list = try displayCommands(for: style(parse("<a>link</a>"), rules: sortedByCascade(defaultStyleRules)))
            .map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "link")
        #expect(item.color == namedColor("blue"))
    }

    @Test func `background-color style paints a matching rectangle`() throws {
        let commands = displayCommands(
            for: style(parse(#"<div style="background-color:blue">x</div>"#), rules: sortedByCascade(defaultStyleRules)),
        )
        #expect(commands.count == 2)
        let rect = try #require(commands.first as? DrawRect)
        #expect(rect.color == namedColor("blue"))
        let text = try #require(commands.last as? DrawText)
        #expect(text.text == "x")
    }
}
