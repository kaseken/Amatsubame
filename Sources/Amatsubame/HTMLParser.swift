struct HTMLParser {
    private let body: String

    init(_ body: String) {
        self.body = body
    }

    func parse() -> Node {
        var stack: [OpenElement] = []
        var buffer = ""
        var inTag = false
        for ch in body {
            switch ch {
            case "<":
                inTag = true
                if !buffer.isEmpty { stack.addText(buffer) }
                buffer = ""
            case ">":
                inTag = false
                stack.addTag(buffer)
                buffer = ""
            default:
                buffer.append(ch)
            }
        }
        if !inTag, !buffer.isEmpty { stack.addText(buffer) }
        return stack.finish()
    }
}

private struct OpenElement {
    let tag: String
    let attributes: [String: String]
    var children: [Node]

    var node: Node {
        .element(tag: tag, attributes: attributes, children: children)
    }
}

private let selfClosingTags: Set<String> = [
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "param", "source", "track", "wbr",
]

private let headTags: Set<String> = [
    "base", "basefont", "bgsound", "noscript",
    "link", "meta", "title", "style", "script",
]

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

private extension [OpenElement] {
    mutating func addText(_ text: String) {
        if text.allSatisfy(\.isWhitespace) { return }
        implicitTags(nil)
        self[count - 1].children.append(.text(text))
    }

    mutating func addTag(_ text: String) {
        let (tag, attributes) = getAttributes(text)
        if tag.hasPrefix("!") { return }
        implicitTags(tag)

        if tag.hasPrefix("/") {
            if count == 1 { return }
            let element = removeLast()
            self[count - 1].children.append(element.node)
        } else if selfClosingTags.contains(tag) {
            self[count - 1].children.append(
                .element(tag: tag, attributes: attributes, children: []),
            )
        } else {
            append(OpenElement(tag: tag, attributes: attributes, children: []))
        }
    }

    mutating func implicitTags(_ tag: String?) {
        while true {
            let openTags = map(\.tag)
            if openTags.isEmpty, tag != "html" {
                addTag("html")
            } else if openTags == ["html"], tag != "head", tag != "body", tag != "/html" {
                addTag(headTags.contains(tag ?? "") ? "head" : "body")
            } else if openTags == ["html", "head"], tag != "/head", !headTags.contains(tag ?? "") {
                addTag("/head")
            } else {
                break
            }
        }
    }

    mutating func finish() -> Node {
        if isEmpty { implicitTags(nil) }
        while count > 1 {
            let element = removeLast()
            self[count - 1].children.append(element.node)
        }
        return removeLast().node
    }
}
