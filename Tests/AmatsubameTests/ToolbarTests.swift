@testable import Amatsubame
import Foundation
import Testing

@MainActor
struct ToolbarTests {
    @Test func `new tab button sits at the top-left corner`() {
        let toolbar = Toolbar()
        #expect(toolbar.newTabRect.left == 5)
        #expect(toolbar.newTabRect.top == 5)
    }

    @Test func `address bar spans from the back button to the right edge`() {
        let toolbar = Toolbar()
        #expect(toolbar.addressRect.left > toolbar.backRect.right)
        #expect(toolbar.addressRect.right == Layout.canvasWidth - 5)
    }

    @Test func `clicking the new tab button requests a new tab`() {
        let toolbar = Toolbar()
        let action = toolbar.click(at: Point(x: toolbar.newTabRect.x + 1, y: toolbar.newTabRect.y + 1), tabCount: 1)
        #expect(action == .newTab)
    }

    @Test func `clicking a tab selects it`() {
        let toolbar = Toolbar()
        let bounds = toolbar.tabRect(1)
        let action = toolbar.click(at: Point(x: bounds.x + 1, y: bounds.y + 1), tabCount: 2)
        #expect(action == .selectTab(1))
    }

    @Test func `clicking the back button requests back`() {
        let toolbar = Toolbar()
        let action = toolbar.click(at: Point(x: toolbar.backRect.x + 1, y: toolbar.backRect.y + 1), tabCount: 1)
        #expect(action == .back)
    }

    @Test func `clicking the address bar focuses and clears it`() {
        let toolbar = Toolbar()
        toolbar.addressBar = "stale"
        let action = toolbar.click(at: Point(x: toolbar.addressRect.x + 1, y: toolbar.addressRect.y + 1), tabCount: 1)
        #expect(action == .focusAddress)
        #expect(toolbar.focus == .addressBar)
        #expect(toolbar.addressBar == "")
    }

    @Test func `keypress edits the address bar only when focused`() {
        let toolbar = Toolbar()
        toolbar.keypress("a")
        #expect(toolbar.addressBar == "")
        toolbar.focus = .addressBar
        toolbar.keypress("a")
        toolbar.keypress("b")
        #expect(toolbar.addressBar == "ab")
        toolbar.backspace()
        #expect(toolbar.addressBar == "a")
    }

    @Test func `enter parses the typed url and clears focus`() throws {
        let toolbar = Toolbar()
        toolbar.focus = .addressBar
        toolbar.addressBar = "https://example.com/"
        let url = try #require(toolbar.enter())
        #expect(url.absoluteString == "https://example.com/")
        #expect(toolbar.focus == .none)
    }

    @Test func `paint renders outlines and text for a tab`() {
        let toolbar = Toolbar()
        let commands = toolbar.paint(tabs: [Tab(viewportHeight: 500)], activeIndex: 0)
        #expect(commands.contains { $0 is DrawOutline })
        #expect(commands.contains { $0 is DrawText })
    }
}
