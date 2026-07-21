@testable import Amatsubame
import Foundation
import Testing

struct LinkHitTestTests {
    private let box = Rect(x: 0, y: 0, width: 100, height: 20)

    @Test func `resolves a relative href against the base url`() throws {
        let base = URL(string: "https://example.com/dir/page.html")
        let links = [LinkTarget(rect: box, href: "next.html")]
        let url = try #require(hitTestLink(x: 10, y: 10, links: links, relativeTo: base))
        #expect(url.absoluteString == "https://example.com/dir/next.html")
    }

    @Test func `resolves an absolute href`() throws {
        let links = [LinkTarget(rect: box, href: "https://other.example/a")]
        let url = try #require(hitTestLink(x: 5, y: 5, links: links, relativeTo: URL(string: "https://example.com/")))
        #expect(url.absoluteString == "https://other.example/a")
    }

    @Test func `misses when the point is outside every target`() {
        let links = [LinkTarget(rect: box, href: "next.html")]
        #expect(hitTestLink(x: 200, y: 10, links: links, relativeTo: URL(string: "https://example.com/")) == nil)
    }

    @Test func `picks the topmost overlapping target`() throws {
        let base = URL(string: "https://example.com/")
        let links = [
            LinkTarget(rect: box, href: "under.html"),
            LinkTarget(rect: box, href: "over.html"),
        ]
        let url = try #require(hitTestLink(x: 10, y: 10, links: links, relativeTo: base))
        #expect(url.absoluteString == "https://example.com/over.html")
    }
}
