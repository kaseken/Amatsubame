import Foundation

enum Pages {
    static func index() -> String {
        resource(named: "index", withExtension: "html")
    }

    static func rendering() -> String {
        resource(named: "rendering", withExtension: "html")
    }

    static func boxDimensions() -> String {
        resource(named: "box-dimensions", withExtension: "html")
    }

    static func form() -> String {
        resource(named: "form", withExtension: "html")
    }

    static func posted(_ message: String) -> String {
        resource(named: "posted", withExtension: "html")
            .replacingOccurrences(of: "<!-- message -->", with: escaped(message))
    }

    static func html(_ name: String) -> String {
        resource(named: name, withExtension: "html")
    }

    static func script(_ name: String) -> String {
        resource(named: name, withExtension: "js")
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
