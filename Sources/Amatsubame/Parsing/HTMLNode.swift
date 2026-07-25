indirect enum HTMLNode: Equatable {
    case text(String)
    case element(tag: String, attributes: [String: String], children: [HTMLNode])
}

extension HTMLNode: CustomStringConvertible {
    var description: String {
        switch self {
        case let .text(text): #""\#(text)""#
        case let .element(tag, _, _): "<\(tag)>"
        }
    }

    func treeDescription() -> String {
        treeDescription(indent: 0)
    }

    private func treeDescription(indent: Int) -> String {
        var lines = [String(repeating: " ", count: indent) + description]
        if case let .element(_, _, children) = self {
            for child in children {
                lines.append(child.treeDescription(indent: indent + 2))
            }
        }
        return lines.joined(separator: "\n")
    }
}
