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
    private var runtime: ScriptRuntime?
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
            let sources = await scriptSources(for: tree, pageURL: url)
            if sources.isEmpty {
                runtime = nil
            } else {
                let scriptRuntime = ScriptRuntime(document: tree)
                for source in sources {
                    scriptRuntime.run(source)
                }
                document = scriptRuntime.document
                runtime = scriptRuntime
            }
            rebuild()
        } catch {
            fputs("Error: \(error)\n", stderr)
        }
    }

    func click(at point: Point) -> ClickOutcome {
        let documentPoint = point.offsetBy(dy: scrollY)
        if let control = formControls.reversed().first(where: { $0.rect.contains(documentPoint) }) {
            if !dispatchEvent(type: "click", at: control.nodePath) { return .redraw }
            return activate(control)
        }
        if let link = links.reversed().first(where: { $0.rect.contains(documentPoint) }) {
            if let linkPath = link.nodePath, !dispatchEvent(type: "click", at: linkPath) { return .redraw }
            guard let destination = URL(string: link.href, relativeTo: url)?.absoluteURL else { return .none }
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
        if let formPath = formPath(containing: controlPath, in: document),
           !dispatchEvent(type: "submit", at: formPath)
        {
            return .redraw
        }
        return .submit(destination, body: form.encodedBody)
    }

    private func formPath(containing controlPath: NodePath, in root: HTMLNode) -> NodePath? {
        for length in stride(from: controlPath.count, through: 0, by: -1) {
            let candidate = Array(controlPath.prefix(length))
            if case let .element(tag, _, _)? = root.node(at: candidate), tag == "form" { return candidate }
        }
        return nil
    }

    private func dispatchEvent(type: String, at path: NodePath) -> Bool {
        guard let runtime else { return true }
        runtime.document = document
        let doDefault = runtime.dispatchEvent(type: type, at: path)
        document = runtime.document
        if !doDefault { rebuild() }
        return doDefault
    }

    private func scriptSources(for tree: HTMLNode, pageURL: URL) async -> [String] {
        var sources: [String] = []
        for href in scriptSourceHrefs(tree) {
            guard let scriptURL = URL(string: href, relativeTo: pageURL),
                  let body = try? await HTTPClient().request(scriptURL)
            else { continue }
            sources.append(body)
        }
        return sources
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
