struct StyledNode {
    let node: HTMLNode
    let style: [String: String]
    let children: [StyledNode]
}

let inheritedDefaults: [String: String] = [
    "font-size": "16px",
    "font-style": "normal",
    "font-weight": "normal",
    "color": "black",
]

private let defaultStyleSheet = """
pre { background-color: gray; }
a { color: blue; }
i { font-style: italic; }
b { font-weight: bold; }
small { font-size: 90%; }
big { font-size: 110%; }
"""

let defaultStyleRules: [CSSRule] = CSSParser(defaultStyleSheet).parse()

func sortedByCascade(_ rules: [CSSRule]) -> [CSSRule] {
    rules.enumerated()
        .sorted { lhs, rhs in
            lhs.element.selector.priority == rhs.element.selector.priority
                ? lhs.offset < rhs.offset
                : lhs.element.selector.priority < rhs.element.selector.priority
        }
        .map(\.element)
}

func style(
    _ node: HTMLNode,
    rules: [CSSRule],
    parentStyle: [String: String] = [:],
    ancestorTags: [String] = [],
) -> StyledNode {
    var computed: [String: String] = [:]
    for (property, defaultValue) in inheritedDefaults {
        computed[property] = parentStyle[property] ?? defaultValue
    }

    if case let .element(tag, attributes, _) = node {
        for rule in rules where rule.selector.matches(tag: tag, ancestorTags: ancestorTags) {
            for (property, value) in rule.declarations {
                computed[property] = value
            }
        }
        if let inlineStyle = attributes["style"] {
            for (property, value) in CSSParser(inlineStyle).body() {
                computed[property] = value
            }
        }
    }
    computed["font-size"] = resolvedFontSize(computed["font-size"], parentStyle: parentStyle)

    let styledChildren: [StyledNode] = if case let .element(tag, _, children) = node {
        children.map {
            style($0, rules: rules, parentStyle: computed, ancestorTags: ancestorTags + [tag])
        }
    } else {
        []
    }
    return StyledNode(node: node, style: computed, children: styledChildren)
}

func linkedStyleSheetHrefs(_ node: HTMLNode) -> [String] {
    guard case let .element(tag, attributes, children) = node else { return [] }
    let ownHref: [String] =
        tag == "link" && attributes["rel"] == "stylesheet"
            ? attributes["href"].map { [$0] } ?? []
            : []
    return ownHref + children.flatMap(linkedStyleSheetHrefs)
}

func embeddedStyleSheets(_ node: HTMLNode) -> [String] {
    guard case let .element(tag, _, children) = node else { return [] }
    let ownCSS: [String] = tag == "style"
        ? [children.compactMap { if case let .text(css) = $0 { css } else { nil } }.joined()]
        : []
    return ownCSS.filter { !$0.isEmpty } + children.flatMap(embeddedStyleSheets)
}

private func resolvedFontSize(_ value: String?, parentStyle: [String: String]) -> String {
    let fallback = inheritedDefaults["font-size"]!
    guard let value else { return fallback }
    let parentValue = parentStyle["font-size"] ?? fallback
    let parentPixels = Double(parentValue.dropLast(2)) ?? 16
    if value.hasSuffix("%") {
        let percent = Double(value.dropLast()) ?? 100
        return "\(percent / 100 * parentPixels)px"
    }
    if value.hasSuffix("em") {
        let ems = Double(value.dropLast(2)) ?? 1
        return "\(ems * parentPixels)px"
    }
    return value
}
