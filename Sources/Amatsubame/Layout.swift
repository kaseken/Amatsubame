import AppKit

struct DisplayItem {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
}

/// Lays text out word by word, wrapping at the canvas edge and aligning words of
/// differing sizes to a shared baseline, following browser.engineering Chapter 3.
struct Layout {
    static let canvasWidth = 800.0
    static let canvasHeight = 600.0
    static let horizontalEdgeMargin = 13.0
    static let verticalEdgeMargin = 18.0
    static let scrollStep = 100.0
    private static let defaultFontSize = 16.0

    private(set) var displayList: [DisplayItem] = []
    private var cursorX = Layout.horizontalEdgeMargin
    private var cursorY = Layout.verticalEdgeMargin
    private var fontWeight: NSFont.Weight = .regular
    private var isFontItalic = false
    private var fontSize = Layout.defaultFontSize

    /// Words on the current line awaiting baseline alignment by ``commitLine()``.
    private var line: [(x: Double, word: String, font: NSFont)] = []

    init(_ tree: Node) {
        recurse(tree)
        commitLine()
    }

    private mutating func recurse(_ node: Node) {
        switch node {
        case let .text(text):
            for word in text.split(whereSeparator: \.isWhitespace) {
                self.word(String(word))
            }
        case let .element(tag, _, children):
            openTag(tag)
            for child in children {
                recurse(child)
            }
            closeTag(tag)
        }
    }

    private mutating func openTag(_ tag: String) {
        switch tag {
        case "b": fontWeight = .bold
        case "i": isFontItalic = true
        case "small": fontSize -= 2
        case "big": fontSize += 4
        case "br": commitLine()
        default: break
        }
    }

    private mutating func closeTag(_ tag: String) {
        switch tag {
        case "b": fontWeight = .regular
        case "i": isFontItalic = false
        case "small": fontSize += 2
        case "big": fontSize -= 4
        case "p":
            commitLine()
            cursorY += Layout.verticalEdgeMargin
        default: break
        }
    }

    private mutating func word(_ word: String) {
        let font = Fonts.get(size: fontSize, weight: fontWeight, italic: isFontItalic)
        let wordWidth = font.width(of: word)
        if cursorX + wordWidth + Layout.horizontalEdgeMargin > Layout.canvasWidth {
            commitLine()
        }
        line.append((x: cursorX, word: word, font: font))
        cursorX += wordWidth + font.width(of: " ")
    }

    private mutating func commitLine() {
        guard !line.isEmpty else { return }
        let maxAscent = line.map(\.font.ascender).max() ?? 0
        let baseline = cursorY + 1.25 * maxAscent
        for item in line {
            let y = baseline - item.font.ascender
            displayList.append(DisplayItem(x: item.x, y: y, text: item.word, font: item.font))
        }
        let maxDescent = line.map(\.font.descent).max() ?? 0
        cursorY = baseline + 1.25 * maxDescent
        cursorX = Layout.horizontalEdgeMargin
        line = []
    }
}
