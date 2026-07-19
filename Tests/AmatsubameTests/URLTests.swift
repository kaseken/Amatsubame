import Testing

@testable import Amatsubame

@Suite struct URLTests {
    @Test func httpURL() throws {
        let url = try URL("http://example.org/index.html")
        #expect(url.scheme == .http)
        #expect(url.host == "example.org")
        #expect(url.port == 80)
        #expect(url.path == "/index.html")
    }

    @Test func httpsURL() throws {
        let url = try URL("https://example.org/")
        #expect(url.scheme == .https)
        #expect(url.host == "example.org")
        #expect(url.port == 443)
        #expect(url.path == "/")
    }

    @Test func customPort() throws {
        let url = try URL("http://localhost:8080/path")
        #expect(url.host == "localhost")
        #expect(url.port == 8080)
        #expect(url.path == "/path")
    }

    @Test func defaultPath() throws {
        let url = try URL("http://example.org")
        #expect(url.path == "/")
    }

    @Test func unsupportedSchemeThrows() {
        #expect(throws: URLParseError.self) {
            try URL("ftp://example.org/")
        }
    }

    @Test func missingSeparatorThrows() {
        #expect(throws: URLParseError.self) {
            try URL("http:example.org/")
        }
    }
}
