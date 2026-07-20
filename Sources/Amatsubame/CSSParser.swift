protocol Selector: Sendable {
    var priority: Int { get }
    func matches(tag: String, ancestorTags: [String]) -> Bool
}

struct TagSelector: Selector {
    let tag: String
    let priority = 1

    func matches(tag: String, ancestorTags _: [String]) -> Bool {
        self.tag == tag
    }
}

struct DescendantSelector: Selector {
    let ancestor: any Selector
    let descendant: any Selector

    var priority: Int {
        ancestor.priority + descendant.priority
    }

    func matches(tag: String, ancestorTags: [String]) -> Bool {
        guard descendant.matches(tag: tag, ancestorTags: ancestorTags) else { return false }
        var remaining = ancestorTags
        while let parentTag = remaining.popLast() {
            if ancestor.matches(tag: parentTag, ancestorTags: remaining) { return true }
        }
        return false
    }
}

typealias CSSRule = (selector: any Selector, declarations: [String: String])

final class CSSParser {
    private enum ParseError: Error {
        case unexpected
    }

    private let characters: [Character]
    private var index = 0

    init(_ input: String) {
        characters = Array(input)
    }

    func parse() -> [CSSRule] {
        var rules: [CSSRule] = []
        while true {
            whitespace()
            guard current != nil else { break }
            do {
                let selector = try parseSelector()
                try literal("{")
                whitespace()
                let declarations = body()
                try literal("}")
                rules.append((selector, declarations))
            } catch {
                if ignoreUntil(["}"]) == "}" {
                    index += 1
                } else {
                    break
                }
            }
        }
        return rules
    }

    func body() -> [String: String] {
        var declarations: [String: String] = [:]
        while let character = current, character != "}" {
            do {
                let (property, value) = try pair()
                declarations[property] = value
                whitespace()
                try literal(";")
                whitespace()
            } catch {
                if ignoreUntil([";", "}"]) == ";" {
                    index += 1
                    whitespace()
                } else {
                    break
                }
            }
        }
        return declarations
    }

    private func parseSelector() throws -> any Selector {
        var selector: any Selector = try TagSelector(tag: word().lowercased())
        whitespace()
        while let character = current, character != "{" {
            let descendant = try TagSelector(tag: word().lowercased())
            selector = DescendantSelector(ancestor: selector, descendant: descendant)
            whitespace()
        }
        return selector
    }

    private func pair() throws -> (property: String, value: String) {
        let property = try word()
        whitespace()
        try literal(":")
        whitespace()
        let value = try word()
        return (property.lowercased(), value.lowercased())
    }

    private var current: Character? {
        index < characters.count ? characters[index] : nil
    }

    private func whitespace() {
        while let character = current, character.isWhitespace {
            index += 1
        }
    }

    private func word() throws -> String {
        let start = index
        while let character = current, character.isLetter || character.isNumber || "#-.%".contains(character) {
            index += 1
        }
        guard index > start else { throw ParseError.unexpected }
        return String(characters[start ..< index])
    }

    private func literal(_ expected: Character) throws {
        guard current == expected else { throw ParseError.unexpected }
        index += 1
    }

    private func ignoreUntil(_ stops: Set<Character>) -> Character? {
        while let character = current {
            if stops.contains(character) { return character }
            index += 1
        }
        return nil
    }
}
