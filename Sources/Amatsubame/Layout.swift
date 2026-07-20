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

private struct BoxFrame {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

private enum LayoutBox {
    case block(node: StyledNode, frame: BoxFrame, children: [LayoutBox])
    case inline(node: StyledNode, frame: BoxFrame, words: [PositionedWord])

    var frame: BoxFrame {
        switch self {
        case let .block(_, frame, _), let .inline(_, frame, _): frame
        }
    }
}

private struct PositionedWord {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
    let color: NSColor
}

func displayCommands(for node: HTMLNode) -> [DisplayCommand] {
    displayCommands(for: style(node, rules: sortedByCascade(defaultStyleRules)))
}

func displayCommands(for styled: StyledNode) -> [DisplayCommand] {
    displayCommands(for: layoutDocument(styled))
}

private func layoutDocument(_ node: StyledNode) -> LayoutBox {
    layoutBlock(
        node,
        x: Layout.horizontalEdgeMargin,
        y: Layout.verticalEdgeMargin,
        width: Layout.canvasWidth - 2 * Layout.horizontalEdgeMargin,
    )
}

private func displayCommands(for box: LayoutBox) -> [DisplayCommand] {
    switch box {
    case let .block(node, frame, children):
        boxCommands(for: node, frame: frame) + children.flatMap { displayCommands(for: $0) }
    case let .inline(node, frame, words):
        boxCommands(for: node, frame: frame)
            + words.map { DrawText(x: $0.x, y: $0.y, text: $0.text, font: $0.font, color: $0.color) }
    }
}

private func boxCommands(for node: StyledNode, frame: BoxFrame) -> [DisplayCommand] {
    guard case .element = node.node,
          let background = node.style["background-color"], background != "transparent"
    else { return [] }
    return [DrawRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height, color: namedColor(background))]
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

func namedColor(_ value: String?) -> NSColor {
    guard let value else { return .black }
    if value.hasPrefix("#") { return hexColor(value) ?? .black }
    return switch value {
    case "blue": .blue
    case "red": .red
    case "green": .green
    case "yellow": .yellow
    case "orange": .orange
    case "purple": .purple
    case "brown": .brown
    case "cyan": .cyan
    case "magenta": .magenta
    case "gray", "grey": .gray
    case "white": .white
    default: .black
    }
}

private func hexColor(_ value: String) -> NSColor? {
    let digits = value.dropFirst()
    guard digits.count == 6, let rgb = Int(digits, radix: 16) else { return nil }
    return NSColor(
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255,
        alpha: 1,
    )
}

private enum InlineToken {
    case word(String, NSFont, NSColor)
    case lineBreak
}

private func inlineTokens(_ node: StyledNode) -> [InlineToken] {
    switch node.node {
    case let .text(text):
        let wordFont = font(for: node.style)
        let color = namedColor(node.style["color"])
        return text.split(whereSeparator: \.isWhitespace).map { .word(String($0), wordFont, color) }
    case let .element(tag, _, _):
        if tag == "br" { return [.lineBreak] }
        return node.children.flatMap(inlineTokens)
    }
}

private struct WrappedWord {
    let x: Double
    let word: String
    let font: NSFont
    let color: NSColor
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
        case let .word(word, font, color):
            let wordWidth = font.width(of: word)
            let wrapped = if state.cursorX + wordWidth > width {
                state.breakingLine()
            } else {
                state
            }
            let placement = WrappedWord(x: wrapped.cursorX, word: word, font: font, color: color)
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
            )
        }
        let maxDescent = line.map(\.font.descent).max() ?? 0
        return PositionState(words: state.words + words, cursorY: baseline + 1.25 * maxDescent)
    }
    return (positioned.words, positioned.cursorY)
}
