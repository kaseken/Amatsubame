@testable import Amatsubame
import AppKit
import Testing

struct LinkTargetTests {
    @Test func `anchor with href produces a link target matching the word box`() throws {
        let box = layoutDocument(style(parse(#"<a href="/next">link</a>"#), rules: sortedByCascade(defaultStyleRules)))
        let links = linkTargets(for: box)
        #expect(links.count == 1)
        let target = try #require(links.first)
        #expect(target.href == "/next")
        let text = try #require(displayCommands(for: box).compactMap { $0 as? DrawText }.first)
        #expect(target.rect.x == text.x)
        #expect(target.rect.y == text.y)
    }

    @Test func `each word of a multi-word anchor is a link target`() {
        let box = layoutDocument(style(parse(#"<a href="/x">two words</a>"#), rules: sortedByCascade(defaultStyleRules)))
        let links = linkTargets(for: box)
        #expect(links.count == 2)
        #expect(links.allSatisfy { $0.href == "/x" })
    }

    @Test func `text outside an anchor has no link targets`() {
        let box = layoutDocument(style(parse("plain text"), rules: sortedByCascade(defaultStyleRules)))
        #expect(linkTargets(for: box).isEmpty)
    }
}
