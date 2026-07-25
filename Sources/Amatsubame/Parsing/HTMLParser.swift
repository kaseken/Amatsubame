struct HTMLParser {
    private let body: String

    init(_ body: String) {
        self.body = body
    }

    func parse() -> HTMLNode {
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
    var children: [HTMLNode]

    var node: HTMLNode {
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
    // NOTE: Falling back to "" handles <>.
    let tag = parts.first.map { $0.lowercased() } ?? ""
    var attributes: [String: String] = [:]
    for part in parts.dropFirst() {
        guard let eq = part.firstIndex(of: "=") else {
            attributes[part.lowercased()] = ""
            continue
        }
        let key = part[..<eq].lowercased()
        let value = String(part[part.index(after: eq)...].unquoted)
        attributes[key] = value
    }
    return (tag, attributes)
}

private extension Substring {
    var unquoted: Substring {
        guard count > 2, let quote = first, quote == "'" || quote == "\"", last == quote else {
            return self
        }
        return dropFirst().dropLast()
    }
}

private extension [OpenElement] {
    mutating func addText(_ text: String) {
        if text.allSatisfy(\.isWhitespace) { return }
        addImplicitTags(before: .text)
        self[count - 1].children.append(.text(text))
    }

    mutating func addTag(_ text: String) {
        let (tag, attributes) = getAttributes(text)
        // NOTE: Skip comments and the doctype declaration (<!-- ... -->, <!doctype>).
        if tag.hasPrefix("!") { return }
        addImplicitTags(before: .tag(tag))

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

    private mutating func addImplicitTags(before next: NextToken) {
        while let implicit = nextImplicitTag(before: next) {
            addTag(implicit)
        }
    }

    private enum NextToken {
        case tag(String)
        case text
        case end

        var isHeadContent: Bool {
            if case let .tag(name) = self { headTags.contains(name) } else { false }
        }

        func isTag(name: String) -> Bool {
            if case let .tag(tag) = self { tag == name } else { false }
        }
    }

    private func nextImplicitTag(before next: NextToken) -> String? {
        let openTags = map(\.tag)
        if openTags.isEmpty {
            if next.isTag(name: "html") { return nil }
            return "html"
        }
        if openTags == ["html"] {
            if next.isTag(name: "head") || next.isTag(name: "body") || next.isTag(name: "/html") { return nil }
            if next.isHeadContent { return "head" }
            return "body"
        }
        if openTags == ["html", "head"] {
            if next.isTag(name: "/head") || next.isHeadContent { return nil }
            return "/head"
        }
        return nil
    }

    mutating func finish() -> HTMLNode {
        if isEmpty { addImplicitTags(before: .end) }
        while count > 1 {
            let element = removeLast()
            self[count - 1].children.append(element.node)
        }
        return removeLast().node
    }
}
