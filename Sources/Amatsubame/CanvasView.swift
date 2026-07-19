import AppKit

final class CanvasView: NSView {
    var displayList: [DisplayItem] = [] {
        didSet { needsDisplay = true }
    }

    var scroll = 0.0

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
            if item.y > scroll + LayoutMetrics.canvasHeight { continue }
            if item.y + LayoutMetrics.verticalStep < scroll { continue }
            let point = NSPoint(x: item.x, y: item.y - scroll)
            (item.text as NSString).draw(at: point, withAttributes: [
                .font: item.font,
                .foregroundColor: NSColor.black,
            ])
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.specialKey {
        case .downArrow:
            scroll += LayoutMetrics.scrollStep
            needsDisplay = true
        case .upArrow:
            scroll = max(0, scroll - LayoutMetrics.scrollStep)
            needsDisplay = true
        default:
            super.keyDown(with: event)
        }
    }
}
