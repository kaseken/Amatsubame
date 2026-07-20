import AppKit

protocol DisplayCommand {
    var top: Double { get }
    var bottom: Double { get }
    func draw(scrollY: Double)
}

struct DrawText: DisplayCommand {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
    let color: NSColor

    var top: Double {
        y
    }

    var bottom: Double {
        y + font.ascender + font.descent
    }

    func draw(scrollY: Double) {
        let point = NSPoint(x: x, y: y - scrollY)
        (text as NSString).draw(at: point, withAttributes: [
            .font: font,
            .foregroundColor: color,
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

    func draw(scrollY: Double) {
        color.setFill()
        NSRect(x: x, y: y - scrollY, width: width, height: height).fill()
    }
}
