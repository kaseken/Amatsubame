import AppKit

enum LayoutMetrics {
    static let canvasWidth = 800.0
    static let canvasHeight = 600.0
    static let horizontalStep = 13.0
    static let verticalStep = 18.0
    static let scrollStep = 100.0
    static let defaultFontSize = 16.0
}

struct DisplayItem {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
}

/// Lays text out word by word, wrapping at the canvas edge and aligning words of
/// differing sizes to a shared baseline, following browser.engineering Chapter 3.
func layout(_ tokens: [Token]) -> [DisplayItem] {
    LayoutEngine(tokens).displayList
}

private struct LayoutEngine {
    private(set) var displayList: [DisplayItem] = []
    private var cursorX = LayoutMetrics.horizontalStep
    private var cursorY = LayoutMetrics.verticalStep
    private var weight: NSFont.Weight = .regular
    private var italic = false
    private var size = LayoutMetrics.defaultFontSize

    /// Words on the current line awaiting baseline alignment by ``commitLine()``.
    private var line: [(x: Double, word: String, font: NSFont)] = []

    init(_ tokens: [Token]) {
        for tok in tokens {
            token(tok)
        }
        commitLine()
    }

    private mutating func token(_ tok: Token) {
        switch tok {
        case let .text(text):
            for word in text.split(whereSeparator: \.isWhitespace) {
                self.word(String(word))
            }
        case let .tag(tag):
            switch tag {
            case "b": weight = .bold
            case "/b": weight = .regular
            case "i": italic = true
            case "/i": italic = false
            case "small": size -= 2
            case "/small": size += 2
            case "big": size += 4
            case "/big": size -= 4
            case "br": commitLine()
            case "/p":
                commitLine()
                cursorY += LayoutMetrics.verticalStep
            default: break
            }
        }
    }

    private mutating func word(_ word: String) {
        let font = Fonts.get(size: size, weight: weight, italic: italic)
        let width = font.width(of: word)
        if cursorX + width > LayoutMetrics.canvasWidth - LayoutMetrics.horizontalStep {
            commitLine()
        }
        line.append((x: cursorX, word: word, font: font))
        cursorX += width + font.width(of: " ")
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
        cursorX = LayoutMetrics.horizontalStep
        line = []
    }
}
