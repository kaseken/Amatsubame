import LocalHTTPServer

private let jsPages: Set<String> = [
    "/js-console",
    "/js-queryselector",
    "/js-click-preventdefault",
    "/js-submit-preventdefault",
    "/js-innerhtml",
]

struct Site {
    func handle(_ request: LocalHTTPServer.Request) -> LocalHTTPServer.Response {
        switch (request.method, request.path) {
        case ("GET", "/"):
            LocalHTTPServer.Response(body: Pages.index())
        case ("GET", "/rendering"):
            LocalHTTPServer.Response(body: Pages.rendering())
        case ("GET", "/box-dimensions"):
            LocalHTTPServer.Response(body: Pages.boxDimensions())
        case ("GET", "/text-align-center"):
            LocalHTTPServer.Response(body: Pages.textAlignCenter())
        case ("GET", "/horizontal-centering"):
            LocalHTTPServer.Response(body: Pages.horizontalCentering())
        case ("GET", "/form"):
            LocalHTTPServer.Response(body: Pages.form())
        case ("GET", "/google"):
            LocalHTTPServer.Response(body: Pages.google())
        case ("POST", "/messages"):
            LocalHTTPServer.Response(body: Pages.posted(decodedMessage(from: request.body) ?? ""))
        case let ("GET", path) where jsPages.contains(path):
            LocalHTTPServer.Response(body: Pages.html(String(path.dropFirst())))
        case let ("GET", path) where path.hasSuffix(".js"):
            LocalHTTPServer.Response(
                contentType: "application/javascript; charset=utf-8",
                body: Pages.script(String(path.dropFirst().dropLast(3))),
            )
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
