@testable import Amatsubame
import Testing

struct StripTagsTests {
    @Test func `plain text`() {
        #expect(stripTags("hello world") == "hello world")
    }

    @Test func `single tag`() {
        #expect(stripTags("<b>bold</b>") == "bold")
    }

    @Test func `nested tags`() {
        #expect(stripTags("<div><p>text</p></div>") == "text")
    }

    @Test func `mixed content`() {
        #expect(stripTags("hello <em>world</em>!") == "hello world!")
    }

    @Test func `empty body`() {
        #expect(stripTags("") == "")
    }

    @Test func `tags only`() {
        #expect(stripTags("<html><head></head></html>") == "")
    }
}
