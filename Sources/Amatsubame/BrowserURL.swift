struct BrowserURL {
    let scheme: String
    let host: String
    let port: Int
    let path: String

    init(_ raw: String) throws {
        guard let separatorRange = raw.range(of: "://") else {
            throw BrowserError.invalidURL("missing scheme separator in: \(raw)")
        }
        scheme = String(raw[..<separatorRange.lowerBound])
        guard scheme == "http" || scheme == "https" else {
            throw BrowserError.invalidURL("unsupported scheme: \(scheme)")
        }

        var rest = String(raw[separatorRange.upperBound...])
        if !rest.contains("/") { rest += "/" }

        let slashIdx = rest.firstIndex(of: "/")!
        let hostPort = String(rest[..<slashIdx])
        path = "/" + String(rest[rest.index(after: slashIdx)...])

        if hostPort.contains(":") {
            let parts = hostPort.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, let p = Int(parts[1]) else {
                throw BrowserError.invalidURL("invalid port in: \(hostPort)")
            }
            host = String(parts[0])
            port = p
        } else {
            host = hostPort
            port = scheme == "https" ? 443 : 80
        }
    }
}
