@testable import Amatsubame
import Testing

func parse(_ html: String) -> Node {
    var parser = HTMLParser(html)
    return parser.parse()
}

struct HTMLParserTests {
    @Test func `plain text is wrapped in implicit html and body`() {
        #expect(parse("hello") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .text("hello"),
            ]),
        ]))
    }

    @Test func `formatting tags nest inside body`() {
        #expect(parse("<b>bold</b>") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .element(tag: "b", attributes: [:], children: [.text("bold")]),
            ]),
        ]))
    }

    @Test func `head-only content goes in an implicit head`() {
        #expect(parse("<title>Hi</title>") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "head", attributes: [:], children: [
                .element(tag: "title", attributes: [:], children: [.text("Hi")]),
            ]),
        ]))
    }

    @Test func `head auto-closes when body content appears`() {
        let tree = parse("<meta>text")
        #expect(tree == .element(tag: "html", attributes: [:], children: [
            .element(tag: "head", attributes: [:], children: [
                .element(tag: "meta", attributes: [:], children: []),
            ]),
            .element(tag: "body", attributes: [:], children: [
                .text("text"),
            ]),
        ]))
    }

    @Test func `self-closing tags become childless leaves`() {
        #expect(parse("<br>") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .element(tag: "br", attributes: [:], children: []),
            ]),
        ]))
    }

    @Test func `attributes are parsed and case-folded`() {
        let tree = parse("<div ID=main CLASS='box' disabled>hi</div>")
        #expect(tree == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .element(
                    tag: "div",
                    attributes: ["id": "main", "class": "box", "disabled": ""],
                    children: [.text("hi")],
                ),
            ]),
        ]))
    }

    @Test func `comments and doctype are skipped`() {
        #expect(parse("<!doctype html><!-- hi -->text") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .text("text"),
            ]),
        ]))
    }

    @Test func `empty body yields html and body only`() {
        #expect(parse("") == .element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: []),
        ]))
    }
}
