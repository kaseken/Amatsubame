enum URLParseError: Error {
    case invalidURL(String)
}

enum URLScheme: String {
    case http
    case https

    var defaultPort: Int {
        switch self {
        case .http: 80
        case .https: 443
        }
    }
}

struct URL {
    let scheme: URLScheme
    let host: String
    let port: Int
    let path: String

    init(_ raw: String) throws {
        guard let separatorRange = raw.range(of: "://") else {
            throw URLParseError.invalidURL("missing scheme separator in: \(raw)")
        }
        let schemeString = String(raw[..<separatorRange.lowerBound])
        guard let parsedScheme = URLScheme(rawValue: schemeString) else {
            throw URLParseError.invalidURL("unsupported scheme: \(schemeString)")
        }
        scheme = parsedScheme

        let rest = String(raw[separatorRange.upperBound...])
        let slashIdx = rest.firstIndex(of: "/")
        let hostPort = slashIdx.map { String(rest[..<$0]) } ?? rest
        path = if let slashIdx {
            "/" + String(rest[rest.index(after: slashIdx)...])
        } else {
            "/"
        }
        (host, port) = try URL.parseHostPort(hostPort, defaultPort: scheme.defaultPort)
    }

    private static func parseHostPort(_ hostPort: String, defaultPort: Int) throws -> (String, Int) {
        guard hostPort.contains(":") else {
            return (hostPort, defaultPort)
        }
        let parts = hostPort.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let port = Int(parts[1]) else {
            throw URLParseError.invalidURL("invalid port in: \(hostPort)")
        }
        return (String(parts[0]), port)
    }
}
