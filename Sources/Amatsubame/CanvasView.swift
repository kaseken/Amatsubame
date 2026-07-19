import AppKit

final class CanvasView: NSView {
    var displayList: [DisplayItem] = [] {
        didSet { needsDisplay = true }
    }

    var scroll = 0.0

    private let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 16),
        .foregroundColor: NSColor.black,
    ]

    /// Top-left origin with y growing downward, matching the layout coordinates.
    override var isFlipped: Bool {
        true
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        dirtyRect.fill()

        for item in displayList {
            if item.y > scroll + Layout.canvasHeight { continue }
            if item.y + Layout.verticalStep < scroll { continue }
            let point = NSPoint(x: item.x, y: item.y - scroll)
            (String(item.c) as NSString).draw(at: point, withAttributes: attributes)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.specialKey {
        case .downArrow:
            scroll += Layout.scrollStep
            needsDisplay = true
        case .upArrow:
            scroll = max(0, scroll - Layout.scrollStep)
            needsDisplay = true
        default:
            super.keyDown(with: event)
        }
    }
}
