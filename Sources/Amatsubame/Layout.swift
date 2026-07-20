import AppKit

struct DisplayItem {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
}

struct Layout {
    static let canvasWidth = 800.0
    static let canvasHeight = 600.0
    static let horizontalEdgeMargin = 13.0
    static let verticalEdgeMargin = 18.0
    static let scrollStep = 100.0
    private static let defaultFontSize = 16.0

    let displayList: [DisplayItem]

    init(_ tree: HTMLNode) {
        var state = State()
        Layout.arrange(node: tree, &state)
        Layout.commitLine(&state)
        displayList = state.displayList
    }

    private struct State {
        var displayList: [DisplayItem] = []
        var cursorX = Layout.horizontalEdgeMargin
        var cursorY = Layout.verticalEdgeMargin
        var fontWeight: NSFont.Weight = .regular
        var isFontItalic = false
        var fontSize = Layout.defaultFontSize
        var line: [(x: Double, word: String, font: NSFont)] = []
    }

    private static func arrange(node: HTMLNode, _ state: inout State) {
        switch node {
        case let .text(text):
            for word in text.split(whereSeparator: \.isWhitespace) {
                appendWordToCurrentLine(String(word), &state)
            }
        case let .element(tag, _, children):
            applyTagFormatting(tag, &state) { state in
                for child in children {
                    arrange(node: child, &state)
                }
            }
        }
    }

    private static func applyTagFormatting(
        _ tag: String, _ state: inout State, around body: (inout State) -> Void,
    ) {
        applyOpeningTagFormatting(tag, &state)
        body(&state)
        applyClosingTagFormatting(tag, &state)
    }

    private static func applyOpeningTagFormatting(_ tag: String, _ state: inout State) {
        switch tag {
        case "b": state.fontWeight = .bold
        case "i": state.isFontItalic = true
        case "small": state.fontSize -= 2
        case "big": state.fontSize += 4
        case "br": commitLine(&state)
        default: break
        }
    }

    private static func applyClosingTagFormatting(_ tag: String, _ state: inout State) {
        switch tag {
        case "b": state.fontWeight = .regular
        case "i": state.isFontItalic = false
        case "small": state.fontSize += 2
        case "big": state.fontSize -= 4
        case "p":
            commitLine(&state)
            state.cursorY += verticalEdgeMargin
        default: break
        }
    }

    private static func appendWordToCurrentLine(_ word: String, _ state: inout State) {
        let font = Fonts.get(size: state.fontSize, weight: state.fontWeight, italic: state.isFontItalic)
        let wordWidth = font.width(of: word)
        if state.cursorX + wordWidth + horizontalEdgeMargin > canvasWidth {
            commitLine(&state)
        }
        state.line.append((x: state.cursorX, word: word, font: font))
        state.cursorX += wordWidth + font.width(of: " ")
    }

    private static func commitLine(_ state: inout State) {
        guard !state.line.isEmpty else { return }
        let maxAscent = state.line.map(\.font.ascender).max() ?? 0
        let baseline = state.cursorY + 1.25 * maxAscent
        for item in state.line {
            let y = baseline - item.font.ascender
            state.displayList.append(DisplayItem(x: item.x, y: y, text: item.word, font: item.font))
        }
        let maxDescent = state.line.map(\.font.descent).max() ?? 0
        state.cursorY = baseline + 1.25 * maxDescent
        state.cursorX = horizontalEdgeMargin
        state.line = []
    }
}
