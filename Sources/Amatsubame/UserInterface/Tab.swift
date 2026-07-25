import AppKit

@MainActor
final class Tab {
    enum ClickOutcome {
        case navigate(URL)
        case submit(URL, body: String)
        case redraw
        case none
    }

    private(set) var url: URL?
    private(set) var commands: [DisplayCommand] = []
    private var links: [LinkTarget] = []
    private var formControls: [FormControlTarget] = []
    private var document: HTMLNode?
    private var rules: [CSSRule] = []
    private var focusedInputPath: NodePath?
    private var history: [URL] = []
    private var documentHeight = 0.0
    private let viewportHeight: Double
    var scrollY = 0.0

    init(viewportHeight: Double) {
        self.viewportHeight = viewportHeight
    }

    func load(_ url: URL, body: String? = nil) async {
        do {
            let responseBody = try await HTTPClient().request(url, method: body == nil ? "GET" : "POST", body: body)
            let tree = HTMLParser(responseBody).parse()
            let linkedRules = await linkedStyleRules(for: tree, pageURL: url)
            let embeddedRules = embeddedStyleSheets(tree).flatMap { CSSParser($0).parse() }
            document = tree
            rules = sortedByCascade(defaultStyleRules + linkedRules + embeddedRules)
            focusedInputPath = nil
            self.url = url
            history.append(url)
            scrollY = 0
            rebuild()
        } catch {
            fputs("Error: \(error)\n", stderr)
        }
    }

    func click(at point: Point) -> ClickOutcome {
        let documentPoint = point.offsetBy(dy: scrollY)
        if let control = formControls.reversed().first(where: { $0.rect.contains(documentPoint) }) {
            return activate(control)
        }
        if let destination = hitTestLink(at: documentPoint, links: links, relativeTo: url) {
            return .navigate(destination)
        }
        if focusedInputPath != nil {
            focusedInputPath = nil
            rebuild()
            return .redraw
        }
        return .none
    }

    func insertCharacter(_ character: Character) -> Bool {
        editFocusedInput { $0 + String(character) }
    }

    func deleteBackward() -> Bool {
        editFocusedInput { String($0.dropLast()) }
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

    private func activate(_ control: FormControlTarget) -> ClickOutcome {
        guard let document else { return .none }
        if control.isButton {
            return submitForm(containing: control.nodePath, in: document)
        }
        focusedInputPath = control.nodePath
        self.document = document.replacingAttribute("value", with: "", at: control.nodePath)
        rebuild()
        return .redraw
    }

    private func submitForm(containing controlPath: NodePath, in document: HTMLNode) -> ClickOutcome {
        guard let form = Form.enclosing(controlPath, in: document),
              let action = form.action,
              let destination = URL(string: action, relativeTo: url)?.absoluteURL
        else { return .none }
        return .submit(destination, body: form.encodedBody)
    }

    private func editFocusedInput(_ transform: (String) -> String) -> Bool {
        guard let focusedInputPath, let document,
              case let .element(_, attributes, _)? = document.node(at: focusedInputPath)
        else { return false }
        let newValue = transform(attributes["value"] ?? "")
        self.document = document.replacingAttribute("value", with: newValue, at: focusedInputPath)
        rebuild()
        return true
    }

    private func rebuild() {
        guard let document else { return }
        let styled = style(document, rules: rules)
        let box = layoutDocument(styled)
        commands = displayCommands(for: box, focusedInputPath: focusedInputPath)
        links = linkTargets(for: box)
        formControls = formControlTargets(for: box)
        documentHeight = box.height
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

func hitTestLink(at point: Point, links: [LinkTarget], relativeTo baseURL: URL?) -> URL? {
    for link in links.reversed() where link.rect.contains(point) {
        if let resolved = URL(string: link.href, relativeTo: baseURL) {
            return resolved.absoluteURL
        }
    }
    return nil
}
