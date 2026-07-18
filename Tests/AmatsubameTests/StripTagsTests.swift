import Testing

@testable import Amatsubame

@Suite struct StripTagsTests {
    @Test func plainText() {
        #expect(stripTags("hello world") == "hello world")
    }

    @Test func singleTag() {
        #expect(stripTags("<b>bold</b>") == "bold")
    }

    @Test func nestedTags() {
        #expect(stripTags("<div><p>text</p></div>") == "text")
    }

    @Test func mixedContent() {
        #expect(stripTags("hello <em>world</em>!") == "hello world!")
    }

    @Test func emptyBody() {
        #expect(stripTags("") == "")
    }

    @Test func tagsOnly() {
        #expect(stripTags("<html><head></head></html>") == "")
    }
}
