import AppKit

@MainActor
protocol CanvasViewDelegate: AnyObject {
    func handleClick(at point: Point)
    func handleKey(_ event: NSEvent)
}

final class CanvasView: NSView {
    var toolbarCommands: [DisplayCommand] = []
    var pageCommands: [DisplayCommand] = []
    var scrollY = 0.0
    var toolbarBottom = 0.0
    weak var delegate: CanvasViewDelegate?

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

        NSGraphicsContext.saveGraphicsState()
        NSRect(x: 0, y: toolbarBottom, width: bounds.width, height: bounds.height - toolbarBottom).clip()
        let pageOffset = NSAffineTransform()
        pageOffset.translateX(by: 0, yBy: toolbarBottom)
        pageOffset.concat()
        for command in pageCommands {
            if command.top > scrollY + Layout.canvasHeight { continue }
            if command.bottom < scrollY { continue }
            command.draw(scrollY: scrollY)
        }
        NSGraphicsContext.restoreGraphicsState()

        for command in toolbarCommands {
            command.draw(scrollY: 0)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        delegate?.handleClick(at: Point(x: location.x, y: location.y))
    }

    override func keyDown(with event: NSEvent) {
        delegate?.handleKey(event)
    }
}
