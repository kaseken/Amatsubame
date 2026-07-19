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
        let (path, authority): (String, String) = if let firstSlashIndex = rest.firstIndex(of: "/") {
            ("/" + String(rest[rest.index(after: firstSlashIndex)...]), String(rest[..<firstSlashIndex]))
        } else {
            ("/", rest)
        }
        self.path = path
        (host, port) = try URL.parseAuthority(authority, defaultPort: scheme.defaultPort)
    }

    private static func parseAuthority(_ authority: String, defaultPort: Int) throws -> (String, Int) {
        let parts = authority.split(separator: ":", maxSplits: 1)
        guard parts.count > 1 else {
            return (authority, defaultPort)
        }
        guard let port = Int(parts[1]) else {
            throw URLParseError.invalidURL("invalid port in: \(authority)")
        }
        return (String(parts[0]), port)
    }
}
