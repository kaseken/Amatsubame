indirect enum Node: Equatable {
    case text(String)
    case element(tag: String, attributes: [String: String], children: [Node])
}

extension Node: CustomStringConvertible {
    var description: String {
        switch self {
        case let .text(text): "\"\(text)\""
        case let .element(tag, _, _): "<\(tag)>"
        }
    }

    func treeDescription(indent: Int = 0) -> String {
        var lines = [String(repeating: " ", count: indent) + description]
        if case let .element(_, _, children) = self {
            for child in children {
                lines.append(child.treeDescription(indent: indent + 2))
            }
        }
        return lines.joined(separator: "\n")
    }
}
