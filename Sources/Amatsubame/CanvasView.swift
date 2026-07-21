import AppKit

final class CanvasView: NSView {
    var chromeCommands: [DisplayCommand] = []
    var pageCommands: [DisplayCommand] = []
    var scrollY = 0.0
    var chromeBottom = 0.0
    weak var browser: Browser?

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
        NSRect(x: 0, y: chromeBottom, width: bounds.width, height: bounds.height - chromeBottom).clip()
        let pageOffset = NSAffineTransform()
        pageOffset.translateX(by: 0, yBy: chromeBottom)
        pageOffset.concat()
        for command in pageCommands {
            if command.top > scrollY + Layout.canvasHeight { continue }
            if command.bottom < scrollY { continue }
            command.draw(scrollY: scrollY)
        }
        NSGraphicsContext.restoreGraphicsState()

        for command in chromeCommands {
            command.draw(scrollY: 0)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        browser?.handleClick(at: Point(x: location.x, y: location.y))
    }

    override func keyDown(with event: NSEvent) {
        browser?.handleKey(event)
    }
}
