import AppKit

@MainActor
final class Browser {
    private let window: NSWindow
    private let canvas = CanvasView()
    private let toolbar = Toolbar()
    private var tabs: [Tab] = []
    private var activeIndex = 0

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Layout.canvasWidth, height: Layout.canvasHeight),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "Amatsubame"
        window.contentView = canvas
        canvas.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    private var activeTab: Tab {
        tabs[activeIndex]
    }

    func newTab(_ url: URL) {
        let tab = Tab(viewportHeight: Layout.canvasHeight - toolbar.bottom)
        tabs.append(tab)
        activeIndex = tabs.count - 1
        load(url)
        render()
    }

    private func load(_ url: URL) {
        let tab = activeTab
        Task { @MainActor in
            await tab.load(url)
            render()
        }
    }

    private func render() {
        canvas.toolbarCommands = toolbar.paint(tabs: tabs, activeIndex: activeIndex)
        canvas.pageCommands = activeTab.commands
        canvas.scrollY = activeTab.scrollY
        canvas.toolbarBottom = toolbar.bottom
        canvas.needsDisplay = true
    }
}

extension Browser: CanvasViewDelegate {
    func handleClick(at point: Point) {
        if point.y < toolbar.bottom {
            switch toolbar.click(at: point, tabCount: tabs.count) {
            case .newTab:
                newTab(defaultURL)
            case let .selectTab(index):
                activeIndex = index
            case .back:
                if let previous = activeTab.goBack() { load(previous) }
            case .focusAddress, .none:
                break
            }
            render()
        } else if let destination = activeTab.click(at: point.offsetBy(dy: -toolbar.bottom)) {
            load(destination)
        }
    }

    func handleKey(_ event: NSEvent) {
        switch event.specialKey {
        case .downArrow where toolbar.focus == .none:
            activeTab.scrollDown()
            render()
            return
        case .upArrow where toolbar.focus == .none:
            activeTab.scrollUp()
            render()
            return
        default:
            break
        }

        guard let character = event.characters?.first else { return }
        if character == "\r" || character == "\n" {
            if let url = toolbar.enter() { load(url) }
            render()
        } else if character == "\u{7F}" || character == "\u{8}" {
            toolbar.backspace()
            render()
        } else if toolbar.focus == .addressBar, let scalar = character.unicodeScalars.first,
                  scalar.value >= 0x20, scalar.value < 0x7F
        {
            toolbar.keypress(character)
            render()
        }
    }
}

private let defaultURL = URL(string: "https://example.com/")!
