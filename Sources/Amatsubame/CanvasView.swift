import AppKit

final class CanvasView: NSView {
    var displayCommands: [DisplayCommand] = [] {
        didSet { needsDisplay = true }
    }

    var scrollY = 0.0

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

        for command in displayCommands {
            if command.top > scrollY + Layout.canvasHeight { continue }
            if command.bottom < scrollY { continue }
            command.draw(scrollY: scrollY)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.specialKey {
        case .downArrow:
            scrollY += Layout.scrollStep
            needsDisplay = true
        case .upArrow:
            scrollY = max(0, scrollY - Layout.scrollStep)
            needsDisplay = true
        default:
            super.keyDown(with: event)
        }
    }
}
