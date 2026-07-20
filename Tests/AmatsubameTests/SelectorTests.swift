@testable import Amatsubame
import Testing

struct SelectorTests {
    @Test func `tag selector matches its tag`() {
        let selector = TagSelector(tag: "p")
        #expect(selector.matches(tag: "p", ancestorTags: []))
        #expect(!selector.matches(tag: "div", ancestorTags: []))
        #expect(selector.priority == 1)
    }

    @Test func `descendant selector requires a matching ancestor`() {
        let selector = DescendantSelector(ancestor: TagSelector(tag: "div"), descendant: TagSelector(tag: "span"))
        #expect(selector.matches(tag: "span", ancestorTags: ["html", "div"]))
        #expect(!selector.matches(tag: "span", ancestorTags: ["html", "body"]))
        #expect(!selector.matches(tag: "div", ancestorTags: ["div"]))
    }

    @Test func `descendant selector priority sums its parts`() {
        let selector = DescendantSelector(ancestor: TagSelector(tag: "div"), descendant: TagSelector(tag: "span"))
        #expect(selector.priority == 2)
    }
}
