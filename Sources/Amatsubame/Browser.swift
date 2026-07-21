import AppKit

@MainActor
final class Browser {
    private let window: NSWindow
    private let canvas = CanvasView()
    private let chrome = Chrome()
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
        canvas.browser = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    private var activeTab: Tab {
        tabs[activeIndex]
    }

    func newTab(_ url: URL) {
        let tab = Tab(viewportHeight: Layout.canvasHeight - chrome.bottom)
        tabs.append(tab)
        activeIndex = tabs.count - 1
        load(url)
        render()
    }

    func handleClick(x: Double, y: Double) {
        if y < chrome.bottom {
            switch chrome.click(x: x, y: y, tabCount: tabs.count) {
            case .newTab:
                newTab(homeURL)
            case let .selectTab(index):
                activeIndex = index
            case .back:
                if let previous = activeTab.goBack() { load(previous) }
            case .focusAddress, .none:
                break
            }
            render()
        } else if let destination = activeTab.click(x: x, y: y - chrome.bottom) {
            load(destination)
        }
    }

    func handleKey(_ event: NSEvent) {
        switch event.specialKey {
        case .downArrow where chrome.focus == .none:
            activeTab.scrollDown()
            render()
            return
        case .upArrow where chrome.focus == .none:
            activeTab.scrollUp()
            render()
            return
        default:
            break
        }

        guard let character = event.characters?.first else { return }
        if character == "\r" || character == "\n" {
            if let url = chrome.enter() { load(url) }
            render()
        } else if character == "\u{7F}" || character == "\u{8}" {
            chrome.backspace()
            render()
        } else if chrome.focus == .addressBar, let scalar = character.unicodeScalars.first,
                  scalar.value >= 0x20, scalar.value < 0x7F
        {
            chrome.keypress(character)
            render()
        }
    }

    private func load(_ url: URL) {
        let tab = activeTab
        Task { @MainActor in
            await tab.load(url)
            render()
        }
    }

    private func render() {
        canvas.chromeCommands = chrome.paint(tabs: tabs, activeIndex: activeIndex)
        canvas.pageCommands = activeTab.commands
        canvas.scrollY = activeTab.scrollY
        canvas.chromeBottom = chrome.bottom
        canvas.needsDisplay = true
    }
}

private let homeURL = URL(string: "https://browser.engineering/")!
