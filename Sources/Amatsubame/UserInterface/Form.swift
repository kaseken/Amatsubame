import Foundation

struct FormField {
    let name: String
    let value: String
}

struct Form {
    let action: String?
    let fields: [FormField]

    var encodedBody: String {
        fields.map(\.encoded).joined(separator: "&")
    }

    static func enclosing(_ nodePath: NodePath, in root: HTMLNode) -> Form? {
        for length in stride(from: nodePath.count, through: 0, by: -1) {
            guard let candidate = root.node(at: Array(nodePath.prefix(length))),
                  case let .element(tag, attributes, _) = candidate, tag == "form"
            else { continue }
            return Form(action: attributes["action"], fields: namedFields(in: candidate))
        }
        return nil
    }

    private static func namedFields(in node: HTMLNode) -> [FormField] {
        guard case let .element(tag, attributes, children) = node else { return [] }
        let ownField: [FormField] =
            tag == "input" && attributes["name"] != nil
                ? [FormField(name: attributes["name"]!, value: attributes["value"] ?? "")]
                : []
        return ownField + children.flatMap(namedFields)
    }
}

private extension FormField {
    var encoded: String {
        "\(Self.percentEncoded(name))=\(Self.percentEncoded(value))"
    }

    static func percentEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }

    static let allowedCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()
}
