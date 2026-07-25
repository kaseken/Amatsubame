@testable import Amatsubame
import AppKit
import Testing

struct DisplayListTests {
    @Test func `single word near origin`() throws {
        let box = layoutDocument(style(parse("hello"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "hello")
        #expect(item.x == Layout.horizontalEdgeMargin)
        // Baseline pushes y below the top margin.
        #expect(item.y >= Layout.verticalEdgeMargin)
    }

    @Test func `one item per word`() throws {
        let box = layoutDocument(style(parse("hello there world"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["hello", "there", "world"])
    }

    @Test func `long text wraps to a new line`() throws {
        let box = layoutDocument(style(parse(String(repeating: "word ", count: 100)), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.count == 100)
        #expect(list.allSatisfy { $0.text == "word" })
        let firstY = try #require(list.first).y
        // Some later word must sit on a lower line, restarting at the left margin.
        #expect(list.contains { $0.y > firstY })
        #expect(list.contains { $0.x == Layout.horizontalEdgeMargin && $0.y > firstY })
    }

    @Test func `bold tag yields a bold font`() throws {
        let box = layoutDocument(style(parse("<b>bold</b>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "bold")
        #expect(NSFontManager.shared.traits(of: item.font).contains(.boldFontMask))
    }

    @Test func `italic tag yields an italic font`() throws {
        let box = layoutDocument(style(parse("<i>slanted</i>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "slanted")
        #expect(NSFontManager.shared.traits(of: item.font).contains(.italicFontMask))
    }

    @Test func `big tag increases font size`() throws {
        let normalBox = layoutDocument(style(parse("word"), rules: sortedByCascade(defaultStyleRules)))
        let normalList = try displayCommands(for: normalBox).map { try #require($0 as? DrawText) }
        let bigBox = layoutDocument(style(parse("<big>word</big>"), rules: sortedByCascade(defaultStyleRules)))
        let bigList = try displayCommands(for: bigBox).map { try #require($0 as? DrawText) }
        #expect(normalList.count == 1)
        #expect(bigList.count == 1)
        let normal = try #require(normalList.first)
        let big = try #require(bigList.first)
        #expect(big.font.pointSize > normal.font.pointSize)
    }

    @Test func `small tag decreases font size`() throws {
        let normalBox = layoutDocument(style(parse("word"), rules: sortedByCascade(defaultStyleRules)))
        let normalList = try displayCommands(for: normalBox).map { try #require($0 as? DrawText) }
        let smallBox = layoutDocument(style(parse("<small>word</small>"), rules: sortedByCascade(defaultStyleRules)))
        let smallList = try displayCommands(for: smallBox).map { try #require($0 as? DrawText) }
        #expect(normalList.count == 1)
        #expect(smallList.count == 1)
        let normal = try #require(normalList.first)
        let small = try #require(smallList.first)
        #expect(small.font.pointSize < normal.font.pointSize)
    }

    @Test func `br starts a new line`() throws {
        let box = layoutDocument(style(parse("first<br>second"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["first", "second"])
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(second.x == Layout.horizontalEdgeMargin)
    }

    @Test func `mixed sizes share a baseline`() throws {
        // Two words on one line: larger word has a taller ascent, so its top (y)
        // sits higher (smaller y) than the smaller word's.
        let box = layoutDocument(style(parse("<big>Big</big> small"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["Big", "small"])
        let big = try #require(list.first)
        let small = try #require(list.last)
        #expect(big.y < small.y)
    }

    @Test func `empty tokens produce no items`() throws {
        let box = layoutDocument(style(parse(""), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.isEmpty)
    }

    @Test func `block elements stack vertically`() throws {
        let box = layoutDocument(style(parse("<div><p>first</p><p>second</p></div>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["first", "second"])
        let first = try #require(list.first)
        let second = try #require(list.last)
        #expect(second.y > first.y)
        #expect(first.x == second.x)
    }

    @Test func `title text is not rendered`() throws {
        let box = layoutDocument(style(parse("<title>Example</title><p>hi</p>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["hi"])
    }

    @Test func `style element css is not rendered`() throws {
        let box = layoutDocument(style(parse("<style>body{color:red}</style><p>hi</p>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.map(\.text) == ["hi"])
    }

    @Test func `pre element paints a background rectangle`() throws {
        let box = layoutDocument(style(parse("<pre>code</pre>"), rules: sortedByCascade(defaultStyleRules)))
        let commands = displayCommands(for: box)
        #expect(commands.count == 2)
        let rect = try #require(commands.first as? DrawRect)
        #expect(rect.color == color(for: "gray"))
        let text = try #require(commands.last as? DrawText)
        #expect(text.text == "code")
    }

    @Test func `anchor text is blue`() throws {
        let box = layoutDocument(style(parse("<a>link</a>"), rules: sortedByCascade(defaultStyleRules)))
        let list = try displayCommands(for: box).map { try #require($0 as? DrawText) }
        #expect(list.count == 1)
        let item = try #require(list.first)
        #expect(item.text == "link")
        #expect(item.color == color(for: "blue"))
    }

    @Test func `background-color style paints a matching rectangle`() throws {
        let box = layoutDocument(style(parse(#"<div style="background-color:blue">x</div>"#), rules: sortedByCascade(defaultStyleRules)))
        let commands = displayCommands(for: box)
        #expect(commands.count == 2)
        let rect = try #require(commands.first as? DrawRect)
        #expect(rect.color == color(for: "blue"))
        let text = try #require(commands.last as? DrawText)
        #expect(text.text == "x")
    }
}
