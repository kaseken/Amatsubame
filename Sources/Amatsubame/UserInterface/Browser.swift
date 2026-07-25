import AppKit

@MainActor
final class Browser {
    private let window: NSWindow
    private let canvas = CanvasView()
    private var tabs: [Tab] = []
    private var activeIndex = 0
    private var addressBar = ""
    private var isAddressBarFocused = false

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
        let tab = Tab(viewportHeight: Layout.canvasHeight - Toolbar.height)
        tabs.append(tab)
        activeIndex = tabs.count - 1
        load(url)
        render()
    }

    private func load(_ url: URL, body: String? = nil) {
        let tab = activeTab
        Task { @MainActor in
            await tab.load(url, body: body)
            render()
        }
    }

    private func render() {
        canvas.toolbarCommands = Toolbar.displayCommands(
            tabs: tabs, activeIndex: activeIndex, addressBar: addressBar, isAddressBarFocused: isAddressBarFocused,
        )
        canvas.pageCommands = activeTab.commands
        canvas.scrollY = activeTab.scrollY
        canvas.toolbarBottom = Toolbar.height
        canvas.needsDisplay = true
    }
}

extension Browser: CanvasViewDelegate {
    func handleClick(at point: Point) {
        if point.y < Toolbar.height {
            switch Toolbar.action(at: point, tabCount: tabs.count) {
            case .newTab:
                isAddressBarFocused = false
                newTab(defaultURL)
            case let .selectTab(index):
                isAddressBarFocused = false
                activeIndex = index
            case .back:
                isAddressBarFocused = false
                if let previous = activeTab.goBack() { load(previous) }
            case .focusAddress:
                isAddressBarFocused = true
                addressBar = ""
            case .none:
                isAddressBarFocused = false
            }
            render()
        } else {
            isAddressBarFocused = false
            switch activeTab.click(at: point.offsetBy(dy: -Toolbar.height)) {
            case let .navigate(destination):
                load(destination)
            case let .submit(destination, body):
                load(destination, body: body)
            case .redraw:
                render()
            case .none:
                break
            }
        }
    }

    func handleKey(_ event: NSEvent) {
        switch event.specialKey {
        case .downArrow where !isAddressBarFocused:
            activeTab.scrollDown()
            render()
            return
        case .upArrow where !isAddressBarFocused:
            activeTab.scrollUp()
            render()
            return
        default:
            break
        }

        guard let character = event.characters?.first else { return }

        if !isAddressBarFocused {
            if character == "\u{7F}" || character == "\u{8}" {
                if activeTab.deleteBackward() { render() }
            } else if isPrintable(character), activeTab.insertCharacter(character) {
                render()
            }
            return
        }

        if character == "\r" || character == "\n" {
            if let url = URL(string: addressBar) { load(url) }
            isAddressBarFocused = false
            render()
        } else if character == "\u{7F}" || character == "\u{8}" {
            if !addressBar.isEmpty { addressBar.removeLast() }
            render()
        } else if isPrintable(character) {
            addressBar.append(character)
            render()
        }
    }
}

private func isPrintable(_ character: Character) -> Bool {
    guard let scalar = character.unicodeScalars.first else { return false }
    return scalar.value >= 0x20 && scalar.value < 0x7F
}

private let defaultURL = URL(string: "https://example.com/")!
