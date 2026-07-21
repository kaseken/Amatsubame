@testable import Amatsubame
import Foundation
import Testing

@MainActor
struct ChromeTests {
    @Test func `new tab button sits at the top-left corner`() {
        let chrome = Chrome()
        #expect(chrome.newTabRect.left == 5)
        #expect(chrome.newTabRect.top == 5)
    }

    @Test func `address bar spans from the back button to the right edge`() {
        let chrome = Chrome()
        #expect(chrome.addressRect.left > chrome.backRect.right)
        #expect(chrome.addressRect.right == Layout.canvasWidth - 5)
    }

    @Test func `clicking the new tab button requests a new tab`() {
        let chrome = Chrome()
        let action = chrome.click(at: Point(x: chrome.newTabRect.x + 1, y: chrome.newTabRect.y + 1), tabCount: 1)
        #expect(action == .newTab)
    }

    @Test func `clicking a tab selects it`() {
        let chrome = Chrome()
        let bounds = chrome.tabRect(1)
        let action = chrome.click(at: Point(x: bounds.x + 1, y: bounds.y + 1), tabCount: 2)
        #expect(action == .selectTab(1))
    }

    @Test func `clicking the back button requests back`() {
        let chrome = Chrome()
        let action = chrome.click(at: Point(x: chrome.backRect.x + 1, y: chrome.backRect.y + 1), tabCount: 1)
        #expect(action == .back)
    }

    @Test func `clicking the address bar focuses and clears it`() {
        let chrome = Chrome()
        chrome.addressBar = "stale"
        let action = chrome.click(at: Point(x: chrome.addressRect.x + 1, y: chrome.addressRect.y + 1), tabCount: 1)
        #expect(action == .focusAddress)
        #expect(chrome.focus == .addressBar)
        #expect(chrome.addressBar == "")
    }

    @Test func `keypress edits the address bar only when focused`() {
        let chrome = Chrome()
        chrome.keypress("a")
        #expect(chrome.addressBar == "")
        chrome.focus = .addressBar
        chrome.keypress("a")
        chrome.keypress("b")
        #expect(chrome.addressBar == "ab")
        chrome.backspace()
        #expect(chrome.addressBar == "a")
    }

    @Test func `enter parses the typed url and clears focus`() throws {
        let chrome = Chrome()
        chrome.focus = .addressBar
        chrome.addressBar = "https://example.com/"
        let url = try #require(chrome.enter())
        #expect(url.absoluteString == "https://example.com/")
        #expect(chrome.focus == .none)
    }

    @Test func `paint renders outlines and text for a tab`() {
        let chrome = Chrome()
        let commands = chrome.paint(tabs: [Tab(viewportHeight: 500)], activeIndex: 0)
        #expect(commands.contains { $0 is DrawOutline })
        #expect(commands.contains { $0 is DrawText })
    }
}
