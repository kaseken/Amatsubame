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
                let tree = HTMLParser(body).parse()
                let linkedRules = await linkedStyleRules(for: tree, pageURL: url)
                let embeddedRules = embeddedStyleSheets(tree).flatMap { CSSParser($0).parse() }
                let styled = style(tree, rules: sortedByCascade(defaultStyleRules + linkedRules + embeddedRules))
                canvas.displayCommands = displayCommands(for: styled)
            } catch {
                fputs("Error: \(error)\n", stderr)
            }
        }
    }

    private func linkedStyleRules(for tree: HTMLNode, pageURL: URL) async -> [CSSRule] {
        var rules: [CSSRule] = []
        for href in linkedStyleSheetHrefs(tree) {
            guard let styleSheetURL = URL(string: href, relativeTo: pageURL),
                  let body = try? await HTTPClient().request(styleSheetURL)
            else { continue }
            rules += CSSParser(body).parse()
        }
        return rules
    }
}
