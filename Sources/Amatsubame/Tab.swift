import AppKit

@MainActor
final class Tab {
    private(set) var url: URL?
    private(set) var commands: [DisplayCommand] = []
    private var links: [LinkTarget] = []
    private var history: [URL] = []
    private var documentHeight = 0.0
    private let viewportHeight: Double
    var scrollY = 0.0

    init(viewportHeight: Double) {
        self.viewportHeight = viewportHeight
    }

    func load(_ url: URL) async {
        do {
            let body = try await HTTPClient().request(url)
            let tree = HTMLParser(body).parse()
            let linkedRules = await linkedStyleRules(for: tree, pageURL: url)
            let embeddedRules = embeddedStyleSheets(tree).flatMap { CSSParser($0).parse() }
            let styled = style(tree, rules: sortedByCascade(defaultStyleRules + linkedRules + embeddedRules))
            let page = layoutPage(for: styled)
            commands = page.commands
            links = page.links
            documentHeight = page.height
            self.url = url
            history.append(url)
            scrollY = 0
        } catch {
            fputs("Error: \(error)\n", stderr)
        }
    }

    func click(x: Double, y: Double) -> URL? {
        hitTestLink(x: x, y: y + scrollY, links: links, relativeTo: url)
    }

    func goBack() -> URL? {
        guard history.count > 1 else { return nil }
        history.removeLast()
        return history.removeLast()
    }

    func scrollDown() {
        scrollY = min(scrollY + Layout.scrollStep, maxScrollY)
    }

    func scrollUp() {
        scrollY = max(0, scrollY - Layout.scrollStep)
    }

    private var maxScrollY: Double {
        max(0, documentHeight + 2 * Layout.verticalEdgeMargin - viewportHeight)
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

func hitTestLink(x: Double, y: Double, links: [LinkTarget], relativeTo baseURL: URL?) -> URL? {
    for link in links.reversed() where link.rect.contains(x: x, y: y) {
        if let resolved = URL(string: link.href, relativeTo: baseURL) {
            return resolved.absoluteURL
        }
    }
    return nil
}
