@testable import Amatsubame
import Testing

struct LexerTests {
    @Test func `plain text`() {
        #expect(lex("hello world") == [.text("hello world")])
    }

    @Test func `single tag`() {
        #expect(lex("<b>bold</b>") == [.tag("b"), .text("bold"), .tag("/b")])
    }

    @Test func `mixed content`() {
        #expect(lex("hello <em>world</em>!") == [
            .text("hello "),
            .tag("em"),
            .text("world"),
            .tag("/em"),
            .text("!"),
        ])
    }

    @Test func `empty body`() {
        #expect(lex("").isEmpty)
    }

    @Test func `tags only`() {
        #expect(lex("<html><head></head></html>") == [
            .tag("html"),
            .tag("head"),
            .tag("/head"),
            .tag("/html"),
        ])
    }
}
