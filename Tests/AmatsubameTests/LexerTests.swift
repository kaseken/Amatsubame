@testable import Amatsubame
import Testing

struct LexerTests {
    @Test func `plain text`() {
        #expect(lex("hello world") == [.text("hello world")])
    }

    @Test func `single tag`() {
        #expect(lex("<b>bold</b>") == [.tag(.boldOpen), .text("bold"), .tag(.boldClose)])
    }

    @Test func `mixed content`() {
        #expect(lex("hello <em>world</em>!") == [
            .text("hello "),
            .tag(.other("em")),
            .text("world"),
            .tag(.other("/em")),
            .text("!"),
        ])
    }

    @Test func `empty body`() {
        #expect(lex("").isEmpty)
    }

    @Test func `unrecognized tags become other`() {
        #expect(lex("<html><head></head></html>") == [
            .tag(.other("html")),
            .tag(.other("head")),
            .tag(.other("/head")),
            .tag(.other("/html")),
        ])
    }

    @Test func `formatting tags parse to cases`() {
        #expect(lex("<i><small><big><br><p></p>") == [
            .tag(.italicOpen),
            .tag(.smallOpen),
            .tag(.bigOpen),
            .tag(.lineBreak),
            .tag(.paragraphOpen),
            .tag(.paragraphClose),
        ])
    }
}
