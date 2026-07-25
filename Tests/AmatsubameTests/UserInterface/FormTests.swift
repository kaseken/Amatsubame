@testable import Amatsubame
import Testing

private let guestbook = HTMLNode.element(tag: "html", attributes: [:], children: [
    .element(tag: "body", attributes: [:], children: [
        .element(tag: "form", attributes: ["action": "/submit"], children: [
            .element(tag: "input", attributes: ["name": "name", "value": "Ada"], children: []),
            .element(tag: "input", attributes: ["name": "comment", "value": "hi there"], children: []),
            .element(tag: "input", attributes: ["value": "no name here"], children: []),
            .element(tag: "button", attributes: [:], children: [.text("Sign")]),
        ]),
    ]),
])

private let buttonPath = [0, 0, 3]

struct FormTests {
    @Test func `enclosing finds the nearest form and reads its action`() {
        #expect(Form.enclosing(buttonPath, in: guestbook)?.action == "/submit")
        #expect(Form.enclosing([0], in: guestbook) == nil)
    }

    @Test func `enclosing gathers named fields and skips unnamed inputs`() {
        let form = Form.enclosing(buttonPath, in: guestbook)
        #expect(form?.fields.map(\.name) == ["name", "comment"])
        #expect(form?.fields.map(\.value) == ["Ada", "hi there"])
    }

    @Test func `encodedBody percent-encodes field names and values`() {
        let form = Form(action: "/x", fields: [
            FormField(name: "q", value: "hello world"),
            FormField(name: "a&b", value: "1=2"),
        ])
        #expect(form.encodedBody == "q=hello%20world&a%26b=1%3D2")
    }
}
