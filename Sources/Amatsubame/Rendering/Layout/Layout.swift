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
    case inline(node: StyledNode, frame: BoxFrame, words: [PositionedWord], formControls: [PositionedFormControl])

    var frame: BoxFrame {
        switch self {
        case let .block(_, frame, _), let .inline(_, frame, _, _): frame
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

struct PositionedFormControl {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let nodePath: NodePath
    let text: String
    let font: NSFont
    let color: NSColor
    let backgroundColor: NSColor
    let isButton: Bool
}

func layoutDocument(_ node: StyledNode) -> LayoutBox {
    layoutBlock(
        node,
        nodePath: [],
        x: Layout.horizontalEdgeMargin,
        y: Layout.verticalEdgeMargin,
        width: Layout.canvasWidth - 2 * Layout.horizontalEdgeMargin,
    )
}

private enum LayoutMode {
    case block
    case inline
}

private func layoutBlock(_ node: StyledNode, nodePath: NodePath, x: Double, y: Double, width: Double) -> LayoutBox {
    switch layoutMode(node) {
    case .block:
        let children = layoutStackedChildren(node.children, parentPath: nodePath, startIndex: 0, x: x, y: y, width: width)
        let height = children.reduce(0) { $0 + $1.frame.height }
        return .block(node: node, frame: BoxFrame(x: x, y: y, width: width, height: height), children: children)
    case .inline:
        let lines = wrapIntoLines(node, nodePath: nodePath, width: width)
        let (words, formControls, height) = positionLines(lines, originX: x, originY: y)
        return .inline(
            node: node,
            frame: BoxFrame(x: x, y: y, width: width, height: height),
            words: words,
            formControls: formControls,
        )
    }
}

private func layoutStackedChildren(
    _ nodes: [StyledNode], parentPath: NodePath, startIndex: Int, x: Double, y: Double, width: Double,
) -> [LayoutBox] {
    guard let first = nodes.first else { return [] }
    let box = layoutBlock(first, nodePath: parentPath + [startIndex], x: x, y: y, width: width)
    return [box] + layoutStackedChildren(
        Array(nodes.dropFirst()), parentPath: parentPath, startIndex: startIndex + 1,
        x: x, y: box.frame.y + box.frame.height, width: width,
    )
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

let inputWidth = 200.0

private struct InlineFragment {
    enum Content {
        case word(text: String, href: String?)
        case formControl(nodePath: NodePath, text: String, backgroundColor: NSColor, isButton: Bool)
    }

    let content: Content
    let width: Double
    let font: NSFont
    let color: NSColor
}

private enum InlineToken {
    case fragment(InlineFragment)
    case lineBreak
}

private let nonRenderedTags: Set<String> = ["head", "title", "style", "script"]

private func inlineTokens(_ node: StyledNode, nodePath: NodePath, linkHref: String? = nil) -> [InlineToken] {
    switch node.node {
    case let .text(text):
        let wordFont = font(for: node.style)
        let wordColor = color(for: node.style["color"])
        return text.split(whereSeparator: \.isWhitespace).map {
            .fragment(InlineFragment(
                content: .word(text: String($0), href: linkHref),
                width: wordFont.width(of: String($0)),
                font: wordFont,
                color: wordColor,
            ))
        }
    case let .element(tag, attributes, _):
        if tag == "br" { return [.lineBreak] }
        if nonRenderedTags.contains(tag) { return [] }
        if tag == "input" || tag == "button" {
            return [.fragment(formControlFragment(node, tag: tag, attributes: attributes, nodePath: nodePath))]
        }
        let enclosingHref = tag == "a" ? (attributes["href"] ?? linkHref) : linkHref
        return node.children.enumerated().flatMap { index, child in
            inlineTokens(child, nodePath: nodePath + [index], linkHref: enclosingHref)
        }
    }
}

private func formControlFragment(
    _ node: StyledNode, tag: String, attributes: [String: String], nodePath: NodePath,
) -> InlineFragment {
    let text = tag == "input" ? (attributes["value"] ?? "") : textContent(node)
    return InlineFragment(
        content: .formControl(
            nodePath: nodePath,
            text: text,
            backgroundColor: color(for: node.style["background-color"]),
            isButton: tag == "button",
        ),
        width: inputWidth,
        font: font(for: node.style),
        color: color(for: node.style["color"]),
    )
}

private func textContent(_ node: StyledNode) -> String {
    switch node.node {
    case let .text(text): text
    case .element: node.children.map(textContent).joined()
    }
}

private struct WrappedFragment {
    let x: Double
    let fragment: InlineFragment
}

private struct WrapState {
    let lines: [[WrappedFragment]]
    let currentLine: [WrappedFragment]
    let cursorX: Double

    func breakingLine() -> WrapState {
        if currentLine.isEmpty {
            return self
        }
        return WrapState(lines: lines + [currentLine], currentLine: [], cursorX: 0)
    }
}

private func wrapIntoLines(_ node: StyledNode, nodePath: NodePath, width: Double) -> [[WrappedFragment]] {
    let start = WrapState(lines: [], currentLine: [], cursorX: 0)
    let placed = inlineTokens(node, nodePath: nodePath).reduce(start) { state, token in
        switch token {
        case .lineBreak:
            return state.breakingLine()
        case let .fragment(fragment):
            let wrapped = if state.cursorX + fragment.width > width {
                state.breakingLine()
            } else {
                state
            }
            let placement = WrappedFragment(x: wrapped.cursorX, fragment: fragment)
            return WrapState(
                lines: wrapped.lines,
                currentLine: wrapped.currentLine + [placement],
                cursorX: wrapped.cursorX + fragment.width + fragment.font.width(of: " "),
            )
        }
    }
    return placed.breakingLine().lines
}

private struct PositionState {
    let words: [PositionedWord]
    let formControls: [PositionedFormControl]
    let cursorY: Double
}

private func positionLines(
    _ lines: [[WrappedFragment]], originX: Double, originY: Double,
) -> (words: [PositionedWord], formControls: [PositionedFormControl], height: Double) {
    let start = PositionState(words: [], formControls: [], cursorY: 0)
    let positioned = lines.reduce(start) { state, line in
        let maxAscent = line.map(\.fragment.font.ascender).max() ?? 0
        let baseline = state.cursorY + 1.25 * maxAscent
        let words = line.compactMap { placed -> PositionedWord? in
            guard case let .word(text, href) = placed.fragment.content else { return nil }
            let wordFont = placed.fragment.font
            return PositionedWord(
                x: originX + placed.x,
                y: originY + baseline - wordFont.ascender,
                text: text,
                font: wordFont,
                color: placed.fragment.color,
                href: href,
            )
        }
        let formControls = line.compactMap { placed -> PositionedFormControl? in
            guard case let .formControl(nodePath, text, backgroundColor, isButton) = placed.fragment.content else {
                return nil
            }
            let controlFont = placed.fragment.font
            return PositionedFormControl(
                x: originX + placed.x,
                y: originY + baseline - controlFont.ascender,
                width: placed.fragment.width,
                height: controlFont.ascender + controlFont.descent,
                nodePath: nodePath,
                text: text,
                font: controlFont,
                color: placed.fragment.color,
                backgroundColor: backgroundColor,
                isButton: isButton,
            )
        }
        let maxDescent = line.map(\.fragment.font.descent).max() ?? 0
        return PositionState(
            words: state.words + words,
            formControls: state.formControls + formControls,
            cursorY: baseline + 1.25 * maxDescent,
        )
    }
    return (positioned.words, positioned.formControls, positioned.cursorY)
}
