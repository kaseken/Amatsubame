import AppKit

@MainActor
final class Browser {
    private let window: NSWindow
    private let canvas = CanvasView()

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Layout.canvasWidth, height: Layout.canvasHeight),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "Amatsubame"
        window.contentView = canvas
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    func load(_ url: URL) {
        Task { @MainActor in
            do {
                let body = try await HTTPClient().request(url)
                canvas.displayList = paintTree(layoutDocument(HTMLParser(body).parse()))
            } catch {
                fputs("Error: \(error)\n", stderr)
            }
        }
    }
}
