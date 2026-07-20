import AppKit

let blockElements: Set<String> = [
    "html", "body", "article", "section", "nav", "aside",
    "h1", "h2", "h3", "h4", "h5", "h6", "hgroup", "header", "footer", "address",
    "p", "hr", "pre", "blockquote", "ol", "ul", "menu", "li", "dl", "dt", "dd",
    "figure", "figcaption", "main", "div", "table", "form", "fieldset", "legend",
    "details", "summary",
]

struct LayoutBox {
    let node: HTMLNode
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let children: [LayoutBox]
    let words: [PositionedWord]
}

struct PositionedWord {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
}

func layoutDocument(_ node: HTMLNode) -> LayoutBox {
    layoutBlock(
        node,
        x: Layout.horizontalEdgeMargin,
        y: Layout.verticalEdgeMargin,
        width: Layout.canvasWidth - 2 * Layout.horizontalEdgeMargin,
    )
}

func paintTree(_ box: LayoutBox) -> [DisplayCommand] {
    paint(box) + box.children.flatMap(paintTree)
}

private enum LayoutMode {
    case block
    case inline
}

private func layoutBlock(_ node: HTMLNode, x: Double, y: Double, width: Double) -> LayoutBox {
    switch layoutMode(node) {
    case .block:
        let children = layoutStackedChildren(childNodes(node), x: x, y: y, width: width)
        let height = children.reduce(0) { $0 + $1.height }
        return LayoutBox(node: node, x: x, y: y, width: width, height: height, children: children, words: [])
    case .inline:
        let lines = wrapIntoLines(node, width: width)
        let (words, height) = positionLines(lines, originX: x, originY: y)
        return LayoutBox(node: node, x: x, y: y, width: width, height: height, children: [], words: words)
    }
}

private func layoutStackedChildren(_ nodes: [HTMLNode], x: Double, y: Double, width: Double) -> [LayoutBox] {
    guard let first = nodes.first else { return [] }
    let box = layoutBlock(first, x: x, y: y, width: width)
    return [box] + layoutStackedChildren(Array(nodes.dropFirst()), x: x, y: box.y + box.height, width: width)
}

private func layoutMode(_ node: HTMLNode) -> LayoutMode {
    switch node {
    case .text:
        return .inline
    case let .element(_, _, children):
        if children.contains(where: isBlockElement) { return .block }
        return children.isEmpty ? .block : .inline
    }
}

private func isBlockElement(_ node: HTMLNode) -> Bool {
    if case let .element(tag, _, _) = node { return blockElements.contains(tag) }
    return false
}

private func childNodes(_ node: HTMLNode) -> [HTMLNode] {
    if case let .element(_, _, children) = node { return children }
    return []
}

private struct FontStyle {
    let size: Double
    let weight: NSFont.Weight
    let italic: Bool

    static let base = FontStyle(size: 16, weight: .regular, italic: false)

    var font: NSFont {
        Fonts.get(size: size, weight: weight, italic: italic)
    }

    func applying(_ tag: String) -> FontStyle {
        switch tag {
        case "b": FontStyle(size: size, weight: .bold, italic: italic)
        case "i": FontStyle(size: size, weight: weight, italic: true)
        case "small": FontStyle(size: size - 2, weight: weight, italic: italic)
        case "big": FontStyle(size: size + 4, weight: weight, italic: italic)
        default: self
        }
    }
}

private enum InlineToken {
    case word(String, NSFont)
    case lineBreak
}

private func inlineTokens(_ node: HTMLNode, style: FontStyle) -> [InlineToken] {
    switch node {
    case let .text(text):
        return text.split(whereSeparator: \.isWhitespace).map { .word(String($0), style.font) }
    case let .element(tag, _, children):
        if tag == "br" { return [.lineBreak] }
        let nestedStyle = style.applying(tag)
        return children.flatMap { inlineTokens($0, style: nestedStyle) }
    }
}

private struct WrappedWord {
    let x: Double
    let word: String
    let font: NSFont
}

private struct WrapState {
    let lines: [[WrappedWord]]
    let currentLine: [WrappedWord]
    let cursorX: Double

    func breakingLine() -> WrapState {
        currentLine.isEmpty ? self : WrapState(lines: lines + [currentLine], currentLine: [], cursorX: 0)
    }
}

private func wrapIntoLines(_ node: HTMLNode, width: Double) -> [[WrappedWord]] {
    let start = WrapState(lines: [], currentLine: [], cursorX: 0)
    let placed = inlineTokens(node, style: .base).reduce(start) { state, token in
        switch token {
        case .lineBreak:
            return state.breakingLine()
        case let .word(word, font):
            let wordWidth = font.width(of: word)
            let wrapped = state.cursorX + wordWidth > width ? state.breakingLine() : state
            let placement = WrappedWord(x: wrapped.cursorX, word: word, font: font)
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
            )
        }
        let maxDescent = line.map(\.font.descent).max() ?? 0
        return PositionState(words: state.words + words, cursorY: baseline + 1.25 * maxDescent)
    }
    return (positioned.words, positioned.cursorY)
}

private func paint(_ box: LayoutBox) -> [DisplayCommand] {
    let background: [DisplayCommand] = if case let .element(tag, _, _) = box.node, tag == "pre" {
        [DrawRect(x: box.x, y: box.y, width: box.width, height: box.height, color: .lightGray)]
    } else {
        []
    }
    let texts = box.words.map { DrawText(x: $0.x, y: $0.y, text: $0.text, font: $0.font) }
    return background + texts
}
