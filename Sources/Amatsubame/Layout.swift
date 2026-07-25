import AppKit

enum Layout {
    static let canvasWidth = 800.0
    static let canvasHeight = 600.0
    static let horizontalEdgeMargin = 13.0
    static let verticalEdgeMargin = 18.0
    static let scrollStep = 100.0
}

private let blockElements: Set<String> = [
    "html", "body", "article", "section", "nav", "aside",
    "h1", "h2", "h3", "h4", "h5", "h6", "hgroup", "header", "footer", "address",
    "p", "hr", "pre", "blockquote", "ol", "ul", "menu", "li", "dl", "dt", "dd",
    "figure", "figcaption", "main", "div", "table", "form", "fieldset", "legend",
    "details", "summary",
]

struct BoxFrame {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

enum LayoutBox {
    case block(node: StyledNode, frame: BoxFrame, children: [LayoutBox])
    case inline(node: StyledNode, frame: BoxFrame, words: [PositionedWord])

    var frame: BoxFrame {
        switch self {
        case let .block(_, frame, _), let .inline(_, frame, _): frame
        }
    }

    var height: Double {
        frame.height
    }
}

struct PositionedWord {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
    let color: NSColor
    let href: String?
}

func layoutDocument(_ node: StyledNode) -> LayoutBox {
    layoutBlock(
        node,
        x: Layout.horizontalEdgeMargin,
        y: Layout.verticalEdgeMargin,
        width: Layout.canvasWidth - 2 * Layout.horizontalEdgeMargin,
    )
}

private enum LayoutMode {
    case block
    case inline
}

private func layoutBlock(_ node: StyledNode, x: Double, y: Double, width: Double) -> LayoutBox {
    switch layoutMode(node) {
    case .block:
        let children = layoutStackedChildren(node.children, x: x, y: y, width: width)
        let height = children.reduce(0) { $0 + $1.frame.height }
        return .block(node: node, frame: BoxFrame(x: x, y: y, width: width, height: height), children: children)
    case .inline:
        let lines = wrapIntoLines(node, width: width)
        let (words, height) = positionLines(lines, originX: x, originY: y)
        return .inline(node: node, frame: BoxFrame(x: x, y: y, width: width, height: height), words: words)
    }
}

private func layoutStackedChildren(_ nodes: [StyledNode], x: Double, y: Double, width: Double) -> [LayoutBox] {
    guard let first = nodes.first else { return [] }
    let box = layoutBlock(first, x: x, y: y, width: width)
    return [box] + layoutStackedChildren(Array(nodes.dropFirst()), x: x, y: box.frame.y + box.frame.height, width: width)
}

private func layoutMode(_ node: StyledNode) -> LayoutMode {
    switch node.node {
    case .text: .inline
    case let .element(_, _, children):
        if children.isEmpty || children.contains(where: isBlockElement) {
            .block
        } else {
            .inline
        }
    }
}

private func isBlockElement(_ node: HTMLNode) -> Bool {
    if case let .element(tag, _, _) = node {
        blockElements.contains(tag)
    } else {
        false
    }
}

private func font(for style: [String: String]) -> NSFont {
    let size = pixels(style["font-size"]) ?? 16
    let weight: NSFont.Weight = style["font-weight"] == "bold" ? .bold : .regular
    let italic = style["font-style"] == "italic"
    return Fonts.get(size: size, weight: weight, italic: italic)
}

private func pixels(_ value: String?) -> Double? {
    guard let value, value.hasSuffix("px") else { return nil }
    return Double(value.dropLast(2))
}

private enum InlineToken {
    case word(String, NSFont, NSColor, String?)
    case lineBreak
}

private let nonRenderedTags: Set<String> = ["head", "title", "style", "script"]

private func inlineTokens(_ node: StyledNode, linkHref: String? = nil) -> [InlineToken] {
    switch node.node {
    case let .text(text):
        let wordFont = font(for: node.style)
        let wordColor = color(for: node.style["color"])
        return text.split(whereSeparator: \.isWhitespace).map { .word(String($0), wordFont, wordColor, linkHref) }
    case let .element(tag, attributes, _):
        if tag == "br" { return [.lineBreak] }
        if nonRenderedTags.contains(tag) { return [] }
        let enclosingHref = tag == "a" ? (attributes["href"] ?? linkHref) : linkHref
        return node.children.flatMap { inlineTokens($0, linkHref: enclosingHref) }
    }
}

private struct WrappedWord {
    let x: Double
    let word: String
    let font: NSFont
    let color: NSColor
    let href: String?
}

private struct WrapState {
    let lines: [[WrappedWord]]
    let currentLine: [WrappedWord]
    let cursorX: Double

    func breakingLine() -> WrapState {
        if currentLine.isEmpty {
            return self
        }
        return WrapState(lines: lines + [currentLine], currentLine: [], cursorX: 0)
    }
}

private func wrapIntoLines(_ node: StyledNode, width: Double) -> [[WrappedWord]] {
    let start = WrapState(lines: [], currentLine: [], cursorX: 0)
    let placed = inlineTokens(node).reduce(start) { state, token in
        switch token {
        case .lineBreak:
            return state.breakingLine()
        case let .word(word, font, color, href):
            let wordWidth = font.width(of: word)
            let wrapped = if state.cursorX + wordWidth > width {
                state.breakingLine()
            } else {
                state
            }
            let placement = WrappedWord(x: wrapped.cursorX, word: word, font: font, color: color, href: href)
            return WrapState(
                lines: wrapped.lines,
                currentLine: wrapped.currentLine + [placement],
                cursorX: wrapped.cursorX + wordWidth + font.width(of: " "),
            )
        }
    }
    return placed.breakingLine().lines
}

private struct PositionState {
    let words: [PositionedWord]
    let cursorY: Double
}

private func positionLines(
    _ lines: [[WrappedWord]], originX: Double, originY: Double,
) -> (words: [PositionedWord], height: Double) {
    let start = PositionState(words: [], cursorY: 0)
    let positioned = lines.reduce(start) { state, line in
        let maxAscent = line.map(\.font.ascender).max() ?? 0
        let baseline = state.cursorY + 1.25 * maxAscent
        let words = line.map { word in
            PositionedWord(
                x: originX + word.x,
                y: originY + baseline - word.font.ascender,
                text: word.word,
                font: word.font,
                color: word.color,
                href: word.href,
            )
        }
        let maxDescent = line.map(\.font.descent).max() ?? 0
        return PositionState(words: state.words + words, cursorY: baseline + 1.25 * maxDescent)
    }
    return (positioned.words, positioned.cursorY)
}
