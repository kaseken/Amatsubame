import LocalHTTPServer

struct Site {
    func handle(_ request: LocalHTTPServer.Request) -> LocalHTTPServer.Response {
        switch (request.method, request.path) {
        case ("GET", "/"):
            LocalHTTPServer.Response(body: Pages.index())
        case ("GET", "/rendering"):
            LocalHTTPServer.Response(body: Pages.rendering())
        case ("GET", "/form"):
            LocalHTTPServer.Response(body: Pages.form())
        case ("POST", "/messages"):
            LocalHTTPServer.Response(body: Pages.posted(decodedMessage(from: request.body) ?? ""))
        default:
            LocalHTTPServer.Response(status: 404, reason: "Not Found", body: "Not Found")
        }
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
