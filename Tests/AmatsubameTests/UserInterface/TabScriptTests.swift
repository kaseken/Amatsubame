@testable import Amatsubame
import Foundation
import LocalHTTPServer
import Testing

@MainActor
struct TabScriptTests {
    @Test func `a linked script runs on load and its DOM changes are rendered`() async throws {
        let server = try LocalHTTPServer { request in
            switch request.path {
            case "/s.js":
                LocalHTTPServer.Response(
                    contentType: "application/javascript",
                    body: "document.querySelectorAll('strong')[0].innerHTML = 'after';",
                )
            default:
                LocalHTTPServer.Response(
                    body: "<html><body><strong>before</strong><script src=\"/s.js\"></script></body></html>",
                )
            }
        }
        let port = try await server.start()
        defer { server.stop() }

        let tab = Tab(viewportHeight: 600)
        try await tab.load(#require(URL(string: "http://127.0.0.1:\(port)/page")))

        let renderedText = tab.commands.compactMap { ($0 as? DrawText)?.text }
        #expect(renderedText.contains("after"))
        #expect(!renderedText.contains("before"))

        let scriptRequested = server.requests.contains { $0.path == "/s.js" }
        #expect(scriptRequested)
    }
}
