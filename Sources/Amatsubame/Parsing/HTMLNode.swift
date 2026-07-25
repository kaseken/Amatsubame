indirect enum HTMLNode: Equatable {
    case text(String)
    case element(tag: String, attributes: [String: String], children: [HTMLNode])
}

/// The address of a node in an `HTMLNode` tree: child indices to follow from the
/// document root. Stable across re-layouts, so it can identify a node over time.
typealias NodePath = [Int]

extension HTMLNode {
    func node(at nodePath: NodePath) -> HTMLNode? {
        guard let firstIndex = nodePath.first else { return self }
        guard case let .element(_, _, children) = self, children.indices.contains(firstIndex) else {
            return nil
        }
        return children[firstIndex].node(at: Array(nodePath.dropFirst()))
    }

    func replacingAttribute(_ key: String, with value: String, at nodePath: NodePath) -> HTMLNode {
        guard case let .element(tag, attributes, children) = self else { return self }
        guard let firstIndex = nodePath.first else {
            var updatedAttributes = attributes
            updatedAttributes[key] = value
            return .element(tag: tag, attributes: updatedAttributes, children: children)
        }
        guard children.indices.contains(firstIndex) else { return self }
        var updatedChildren = children
        updatedChildren[firstIndex] = children[firstIndex]
            .replacingAttribute(key, with: value, at: Array(nodePath.dropFirst()))
        return .element(tag: tag, attributes: attributes, children: updatedChildren)
    }

    func replacingChildren(with newChildren: [HTMLNode], at nodePath: NodePath) -> HTMLNode {
        guard case let .element(tag, attributes, children) = self else { return self }
        guard let firstIndex = nodePath.first else {
            return .element(tag: tag, attributes: attributes, children: newChildren)
        }
        guard children.indices.contains(firstIndex) else { return self }
        var updatedChildren = children
        updatedChildren[firstIndex] = children[firstIndex]
            .replacingChildren(with: newChildren, at: Array(nodePath.dropFirst()))
        return .element(tag: tag, attributes: attributes, children: updatedChildren)
    }

    func elementPaths(matching selector: any Selector) -> [NodePath] {
        elementPaths(matching: selector, prefix: [], ancestorTags: [])
    }

    private func elementPaths(
        matching selector: any Selector, prefix: NodePath, ancestorTags: [String],
    ) -> [NodePath] {
        guard case let .element(tag, _, children) = self else { return [] }
        let ownMatch = selector.matches(tag: tag, ancestorTags: ancestorTags) ? [prefix] : []
        let childMatches = children.enumerated().flatMap { index, child in
            child.elementPaths(matching: selector, prefix: prefix + [index], ancestorTags: ancestorTags + [tag])
        }
        return ownMatch + childMatches
    }
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
