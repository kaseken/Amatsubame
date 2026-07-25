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

struct CSSParser {
    private let characters: [Character]

    init(_ input: String) {
        characters = Array(input)
    }

    func parse() -> [CSSRule] {
        parseStyleSheet(Cursor(characters: characters, index: 0))
    }

    func body() -> [String: String] {
        parseDeclarations(Cursor(characters: characters, index: 0)).declarations
    }
}

private struct Cursor {
    let characters: [Character]
    let index: Int

    var current: Character? {
        index < characters.count ? characters[index] : nil
    }

    func advanced() -> Cursor {
        Cursor(characters: characters, index: index + 1)
    }

    func skippingWhitespace() -> Cursor {
        var cursor = self
        while let character = cursor.current, character.isWhitespace {
            cursor = cursor.advanced()
        }
        return cursor
    }
}

private enum ParseError: Error {
    case unexpected
}

private func parseStyleSheet(_ start: Cursor) -> [CSSRule] {
    var rules: [CSSRule] = []
    var cursor = start.skippingWhitespace()
    while cursor.current != nil {
        do {
            let (selector, afterSelector) = try parseSelector(cursor)
            guard afterSelector.current == "{" else { throw ParseError.unexpected }
            let (declarations, afterBody) = parseDeclarations(afterSelector.advanced().skippingWhitespace())
            guard afterBody.current == "}" else { throw ParseError.unexpected }
            rules.append((selector, declarations))
            cursor = afterBody.advanced().skippingWhitespace()
        } catch {
            let (stop, afterSkip) = skip(until: ["}"], cursor)
            guard stop == "}" else { break }
            cursor = afterSkip.advanced().skippingWhitespace()
        }
    }
    return rules
}

private func parseDeclarations(_ start: Cursor) -> (declarations: [String: String], rest: Cursor) {
    var declarations: [String: String] = [:]
    var cursor = start
    while let character = cursor.current, character != "}" {
        do {
            let (property, value, afterValue) = try parseDeclaration(cursor)
            declarations[property] = value
            let afterWhitespace = afterValue.skippingWhitespace()
            guard afterWhitespace.current == ";" else { throw ParseError.unexpected }
            cursor = afterWhitespace.advanced().skippingWhitespace()
        } catch {
            let (stop, afterSkip) = skip(until: [";", "}"], cursor)
            guard stop == ";" else { return (declarations, afterSkip) }
            cursor = afterSkip.advanced().skippingWhitespace()
        }
    }
    return (declarations, cursor)
}

private func parseSelector(_ start: Cursor) throws -> (selector: any Selector, rest: Cursor) {
    let (first, afterFirst) = try parseWord(start)
    var selector: any Selector = TagSelector(tag: first.lowercased())
    var cursor = afterFirst.skippingWhitespace()
    while let character = cursor.current, character != "{" {
        let (descendant, afterDescendant) = try parseWord(cursor)
        selector = DescendantSelector(ancestor: selector, descendant: TagSelector(tag: descendant.lowercased()))
        cursor = afterDescendant.skippingWhitespace()
    }
    return (selector, cursor)
}

private func parseDeclaration(_ start: Cursor) throws -> (property: String, value: String, rest: Cursor) {
    let (property, afterProperty) = try parseWord(start)
    let beforeColon = afterProperty.skippingWhitespace()
    guard beforeColon.current == ":" else { throw ParseError.unexpected }
    let (value, afterValue) = try parseWord(beforeColon.advanced().skippingWhitespace())
    return (property.lowercased(), value.lowercased(), afterValue)
}

private func parseWord(_ start: Cursor) throws -> (value: String, rest: Cursor) {
    var cursor = start
    while let character = cursor.current, character.isLetter || character.isNumber || "#-.%".contains(character) {
        cursor = cursor.advanced()
    }
    guard cursor.index > start.index else { throw ParseError.unexpected }
    return (String(start.characters[start.index ..< cursor.index]), cursor)
}

private func skip(until stops: Set<Character>, _ start: Cursor) -> (stop: Character?, rest: Cursor) {
    var cursor = start
    while let character = cursor.current {
        if stops.contains(character) { return (character, cursor) }
        cursor = cursor.advanced()
    }
    return (nil, cursor)
}
