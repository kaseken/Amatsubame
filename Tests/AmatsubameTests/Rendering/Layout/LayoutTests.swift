@testable import Amatsubame
import Testing

struct LayoutTests {
    private func layout(_ html: String) -> LayoutBox {
        layoutDocument(style(parse(html), rules: sortedByCascade(defaultStyleRules)))
    }

    private func childBoxes(of box: LayoutBox) -> [LayoutBox] {
        if case let .block(_, _, children) = box { return children }
        return []
    }

    @Test func `document layout reports a positive height for content`() {
        let box = layout("hello")
        #expect(box.height > 0)
    }

    @Test func `explicit width overrides the default content width`() {
        let body = childBoxes(of: layout(#"<div style="width: 300px">hi</div>"#))[0]
        let div = childBoxes(of: body)[0]
        #expect(div.frame.width == 300)
        #expect(div.frame.x == body.frame.x)
    }

    @Test func `explicit height overrides the content-derived height`() {
        let body = childBoxes(of: layout(#"<div style="height: 150px">hi</div>"#))[0]
        let div = childBoxes(of: body)[0]
        #expect(div.frame.height == 150)
    }

    @Test func `explicit height pushes the following sibling down`() {
        let body = childBoxes(of: layout(#"<div style="height: 150px">first</div><div>second</div>"#))[0]
        let first = childBoxes(of: body)[0]
        let second = childBoxes(of: body)[1]
        #expect(first.frame.height == 150)
        #expect(second.frame.y == first.frame.y + 150)
    }

    @Test func `a narrower child block is left-aligned within its parent`() {
        let body = childBoxes(of: layout(#"<div><div style="width: 100px">hi</div></div>"#))[0]
        let outer = childBoxes(of: body)[0]
        let inner = childBoxes(of: outer)[0]
        #expect(inner.frame.width == 100)
        #expect(inner.frame.x == outer.frame.x)
    }

    @Test func `a parent without explicit height sums its children heights`() {
        let html = #"<div><div style="height: 40px">a</div><div style="height: 70px">b</div><div style="height: 30px">c</div></div>"#
        let parent = childBoxes(of: childBoxes(of: layout(html))[0])[0]
        #expect(parent.frame.height == 140)
    }

    @Test func `a narrower explicit width wraps inline text into more lines`() {
        let sentence = "one two three four five six seven eight nine ten eleven twelve"
        let wide = childBoxes(of: childBoxes(of: layout(#"<div style="width: 400px">\#(sentence)</div>"#))[0])[0]
        let narrow = childBoxes(of: childBoxes(of: layout(#"<div style="width: 100px">\#(sentence)</div>"#))[0])[0]
        #expect(narrow.frame.width == 100)
        #expect(narrow.frame.height > wide.frame.height)
    }

    private func words(of box: LayoutBox) -> [PositionedWord] {
        if case let .inline(_, _, words, _) = box { return words }
        return []
    }

    @Test func `text-align center offsets words to the right of the left edge`() {
        let centered = childBoxes(of: layout(#"<div style="text-align: center">hi</div>"#))[0]
        let left = childBoxes(of: layout("<div>hi</div>"))[0]
        let centeredWord = words(of: childBoxes(of: centered)[0])[0]
        let leftWord = words(of: childBoxes(of: left)[0])[0]
        #expect(centeredWord.x > leftWord.x)
    }

    @Test func `text-align center inherits into a nested block`() {
        let outer = childBoxes(of: layout(#"<div style="text-align: center"><p>hi</p></div>"#))[0]
        let paragraph = childBoxes(of: childBoxes(of: outer)[0])[0]
        let word = words(of: paragraph)[0]
        #expect(word.x > paragraph.frame.x)
    }

    @Test func `margin auto centers a fixed-width block within its parent`() {
        let body = childBoxes(of: layout(#"<div style="width: 200px; margin: auto">hi</div>"#))[0]
        let div = childBoxes(of: body)[0]
        #expect(div.frame.width == 200)
        #expect(div.frame.x == body.frame.x + (body.frame.width - 200) / 2)
    }

    @Test func `a block without explicit dimensions fills the width and fits its content`() {
        let body = childBoxes(of: layout("<div>hi</div>"))[0]
        let div = childBoxes(of: body)[0]
        #expect(div.frame.width == body.frame.width)
        #expect(div.frame.height > 0)
        #expect(div.frame.height < 150)
    }
}
