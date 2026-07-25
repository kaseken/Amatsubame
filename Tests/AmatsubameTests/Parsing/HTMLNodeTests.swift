@testable import Amatsubame
import Testing

struct HTMLNodeTests {
    @Test func `text node renders as a quoted string`() {
        #expect(HTMLNode.text("hi").treeDescription() == "\"hi\"")
    }

    @Test func `element node renders as an angle-bracketed tag`() {
        #expect(HTMLNode.element(tag: "br", attributes: [:], children: []).treeDescription() == "<br>")
    }

    @Test func `children are indented by two spaces per level`() {
        let tree = HTMLNode.element(tag: "html", attributes: [:], children: [
            .element(tag: "body", attributes: [:], children: [
                .text("hi"),
            ]),
        ])
        #expect(tree.treeDescription() == """
        <html>
          <body>
            "hi"
        """)
    }

    @Test func `siblings each appear on their own line`() {
        let tree = HTMLNode.element(tag: "body", attributes: [:], children: [
            .text("a"),
            .element(tag: "br", attributes: [:], children: []),
            .text("b"),
        ])
        #expect(tree.treeDescription() == """
        <body>
          "a"
          <br>
          "b"
        """)
    }

    @Test func `node(at:) walks child indices to the addressed node`() {
        #expect(sampleTree.node(at: [0, 0]) == .element(
            tag: "input", attributes: ["name": "q", "value": "Ada"], children: [],
        ))
        #expect(sampleTree.node(at: []) == sampleTree)
        #expect(sampleTree.node(at: [9]) == nil)
    }

    @Test func `replacingAttribute updates one node without mutating the original`() {
        let updated = sampleTree.replacingAttribute("value", with: "Grace", at: [0, 0])
        #expect(updated.node(at: [0, 0]) == .element(
            tag: "input", attributes: ["name": "q", "value": "Grace"], children: [],
        ))
        #expect(updated.node(at: [0, 1]) == sampleTree.node(at: [0, 1]))
        #expect(sampleTree.node(at: [0, 0]) == .element(
            tag: "input", attributes: ["name": "q", "value": "Ada"], children: [],
        ))
    }
}

private let sampleTree = HTMLNode.element(tag: "html", attributes: [:], children: [
    .element(tag: "body", attributes: [:], children: [
        .element(tag: "input", attributes: ["name": "q", "value": "Ada"], children: []),
        .element(tag: "input", attributes: ["name": "lang", "value": "sv"], children: []),
    ]),
])
