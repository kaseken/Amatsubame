@testable import Amatsubame
import Foundation
import Testing

struct HTTPClientPostTests {
    @Test func `POST sends a form-encoded body and returns the response`() async throws {
        let server = try LocalHTTPServer { request in
            LocalHTTPServer.Response(body: "\(request.method):\(request.body)")
        }
        let port = try await server.start()
        defer { server.stop() }

        let url = try #require(URL(string: "http://127.0.0.1:\(port)/submit"))
        let response = try await HTTPClient().request(url, method: "POST", body: "name=Ada&comment=hi%20there")

        #expect(response == "POST:name=Ada&comment=hi%20there")

        let received = try #require(server.requests.first)
        #expect(received.method == "POST")
        #expect(received.path == "/submit")
        #expect(received.body == "name=Ada&comment=hi%20there")
        #expect(received.headers["content-type"] == "application/x-www-form-urlencoded")
    }

    @Test func `GET still works with the default arguments`() async throws {
        let server = try LocalHTTPServer { _ in
            LocalHTTPServer.Response(body: "<html><body>ok</body></html>")
        }
        let port = try await server.start()
        defer { server.stop() }

        let url = try #require(URL(string: "http://127.0.0.1:\(port)/"))
        let response = try await HTTPClient().request(url)

        #expect(response == "<html><body>ok</body></html>")
        #expect(server.requests.first?.method == "GET")
    }
}
