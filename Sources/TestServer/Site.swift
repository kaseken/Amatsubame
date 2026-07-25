import Foundation
import LocalHTTPServer

final class Site: @unchecked Sendable {
    private var messages: [String] = ["Welcome! Leave a message below."]
    private let lock = NSLock()

    func handle(_ request: LocalHTTPServer.Request) -> LocalHTTPServer.Response {
        switch (request.method, request.path) {
        case ("GET", "/"):
            return LocalHTTPServer.Response(body: Pages.showcase())
        case ("GET", "/styles.css"):
            return LocalHTTPServer.Response(contentType: "text/css; charset=utf-8", body: Pages.styles())
        case ("GET", "/submissions"):
            return LocalHTTPServer.Response(body: Pages.submissions(currentMessages()))
        case ("POST", "/submit"):
            if let message = decodedMessage(from: request.body), !message.isEmpty {
                appendMessage(message)
            }
            return LocalHTTPServer.Response(body: Pages.submissions(currentMessages()))
        default:
            return LocalHTTPServer.Response(status: 404, reason: "Not Found", body: "Not Found")
        }
    }

    private func currentMessages() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    private func appendMessage(_ message: String) {
        lock.lock()
        messages.append(message)
        lock.unlock()
    }

    private func decodedMessage(from body: String) -> String? {
        for pair in body.split(separator: "&") {
            let nameAndValue = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard nameAndValue.count == 2, nameAndValue[0] == "message" else { continue }
            return formDecode(String(nameAndValue[1]))
        }
        return nil
    }

    private func formDecode(_ value: String) -> String {
        value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? value
    }
}
