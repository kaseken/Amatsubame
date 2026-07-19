@testable import Amatsubame
import Testing

struct NodeTests {
    @Test func `text node renders as a quoted string`() {
        #expect(Node.text("hi").treeDescription() == "\"hi\"")
    }

    @Test func `element node renders as an angle-bracketed tag`() {
        #expect(Node.element(tag: "br", attributes: [:], children: []).treeDescription() == "<br>")
    }

    @Test func `children are indented by two spaces per level`() {
        let tree = Node.element(tag: "html", attributes: [:], children: [
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
        let tree = Node.element(tag: "body", attributes: [:], children: [
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
}
