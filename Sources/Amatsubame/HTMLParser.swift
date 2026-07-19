struct HTMLParser {
    private static let selfClosingTags: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr",
    ]

    private static let headTags: Set<String> = [
        "base", "basefont", "bgsound", "noscript",
        "link", "meta", "title", "style", "script",
    ]

    private let body: String

    private var stack: [(tag: String, attributes: [String: String], children: [Node])] = []

    init(_ body: String) {
        self.body = body
    }

    mutating func parse() -> Node {
        var buffer = ""
        var inTag = false
        for ch in body {
            switch ch {
            case "<":
                inTag = true
                if !buffer.isEmpty { addText(buffer) }
                buffer = ""
            case ">":
                inTag = false
                addTag(buffer)
                buffer = ""
            default:
                buffer.append(ch)
            }
        }
        if !inTag, !buffer.isEmpty { addText(buffer) }
        return finish()
    }

    private func getAttributes(_ text: String) -> (tag: String, attributes: [String: String]) {
        let parts = text.split(whereSeparator: \.isWhitespace)
        let tag = parts.first.map { $0.lowercased() } ?? ""
        var attributes: [String: String] = [:]
        for part in parts.dropFirst() {
            if let eq = part.firstIndex(of: "=") {
                let key = part[..<eq].lowercased()
                var value = String(part[part.index(after: eq)...])
                if value.count > 2, value.first == "'" || value.first == "\"" {
                    value = String(value.dropFirst().dropLast())
                }
                attributes[key] = value
            } else {
                attributes[part.lowercased()] = ""
            }
        }
        return (tag, attributes)
    }

    private mutating func addText(_ text: String) {
        if text.allSatisfy(\.isWhitespace) { return }
        implicitTags(nil)
        stack[stack.count - 1].children.append(.text(text))
    }

    private mutating func addTag(_ text: String) {
        let (tag, attributes) = getAttributes(text)
        if tag.hasPrefix("!") { return }
        implicitTags(tag)

        if tag.hasPrefix("/") {
            if stack.count == 1 { return }
            let node = stack.removeLast()
            stack[stack.count - 1].children.append(
                .element(tag: node.tag, attributes: node.attributes, children: node.children),
            )
        } else if Self.selfClosingTags.contains(tag) {
            stack[stack.count - 1].children.append(
                .element(tag: tag, attributes: attributes, children: []),
            )
        } else {
            stack.append((tag: tag, attributes: attributes, children: []))
        }
    }

    private mutating func implicitTags(_ tag: String?) {
        while true {
            let openTags = stack.map(\.tag)
            if openTags.isEmpty, tag != "html" {
                addTag("html")
            } else if openTags == ["html"], tag != "head", tag != "body", tag != "/html" {
                addTag(Self.headTags.contains(tag ?? "") ? "head" : "body")
            } else if openTags == ["html", "head"], tag != "/head", !Self.headTags.contains(tag ?? "") {
                addTag("/head")
            } else {
                break
            }
        }
    }

    private mutating func finish() -> Node {
        if stack.isEmpty { implicitTags(nil) }
        while stack.count > 1 {
            let node = stack.removeLast()
            stack[stack.count - 1].children.append(
                .element(tag: node.tag, attributes: node.attributes, children: node.children),
            )
        }
        let root = stack.removeLast()
        return .element(tag: root.tag, attributes: root.attributes, children: root.children)
    }
}
