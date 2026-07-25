import Foundation

enum Pages {
    static func showcase() -> String {
        resource(named: "showcase", withExtension: "html")
    }

    static func submissions(_ messages: [String]) -> String {
        let listed = messages.map { "<p>\(escaped($0))</p>" }.joined(separator: "\n    ")
        return resource(named: "submissions", withExtension: "html")
            .replacingOccurrences(of: "<!-- messages -->", with: listed)
    }

    static func styles() -> String {
        resource(named: "styles", withExtension: "css")
    }

    private static func resource(named name: String, withExtension ext: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return "Missing resource: \(name).\(ext)"
        }
        return contents
    }

    private static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
