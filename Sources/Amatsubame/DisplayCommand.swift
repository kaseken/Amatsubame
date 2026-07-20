import AppKit

protocol DisplayCommand {
    var top: Double { get }
    var bottom: Double { get }
    func draw(scroll: Double)
}

struct DrawText: DisplayCommand {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont

    var top: Double {
        y
    }

    var bottom: Double {
        y + font.ascender + font.descent
    }

    func draw(scroll: Double) {
        let point = NSPoint(x: x, y: y - scroll)
        (text as NSString).draw(at: point, withAttributes: [
            .font: font,
            .foregroundColor: NSColor.black,
        ])
    }
}

struct DrawRect: DisplayCommand {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let color: NSColor

    var top: Double {
        y
    }

    var bottom: Double {
        y + height
    }

    func draw(scroll: Double) {
        color.setFill()
        NSRect(x: x, y: y - scroll, width: width, height: height).fill()
    }
}
