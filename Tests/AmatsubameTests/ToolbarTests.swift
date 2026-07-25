@testable import Amatsubame
import Testing

@MainActor
struct ToolbarTests {
    @Test func `clicking the rendered new-tab button returns newTab`() throws {
        let commands = Toolbar.displayCommands(tabs: [], activeIndex: 0, addressBar: "", isAddressBarFocused: false)
        let plus = try #require(commands.compactMap { $0 as? DrawText }.first { $0.text == "+" })
        #expect(Toolbar.action(at: Point(x: plus.x + 1, y: plus.y + 1), tabCount: 0) == .newTab)
    }

    @Test func `clicking the rendered back button returns back`() throws {
        let commands = Toolbar.displayCommands(tabs: [], activeIndex: 0, addressBar: "", isAddressBarFocused: false)
        let back = try #require(commands.compactMap { $0 as? DrawText }.first { $0.text == "<" })
        #expect(Toolbar.action(at: Point(x: back.x + 1, y: back.y + 1), tabCount: 0) == .back)
    }

    @Test func `clicking a rendered tab selects it`() throws {
        let tabs = [Tab(viewportHeight: 500), Tab(viewportHeight: 500)]
        let commands = Toolbar.displayCommands(tabs: tabs, activeIndex: 0, addressBar: "", isAddressBarFocused: false)
        let label = try #require(commands.compactMap { $0 as? DrawText }.first { $0.text == "Tab 1" })
        #expect(Toolbar.action(at: Point(x: label.x + 1, y: label.y + 1), tabCount: tabs.count) == .selectTab(1))
    }

    @Test func `clicking the rendered address field returns focusAddress`() throws {
        let commands = Toolbar.displayCommands(tabs: [], activeIndex: 0, addressBar: "", isAddressBarFocused: false)
        let field = try #require(commands.compactMap { $0 as? DrawOutline }.max { $0.width < $1.width })
        #expect(Toolbar.action(at: Point(x: field.x + 1, y: field.y + 1), tabCount: 0) == .focusAddress)
    }

    @Test func `a click outside every control returns none`() {
        #expect(Toolbar.action(at: Point(x: Layout.canvasWidth - 1, y: 1), tabCount: 0) == .none)
    }

    @Test func `the address field renders the typed text while editing`() {
        let commands = Toolbar.displayCommands(tabs: [], activeIndex: 0, addressBar: "abc", isAddressBarFocused: true)
        #expect(commands.compactMap { $0 as? DrawText }.contains { $0.text == "abc" })
    }

    @Test func `display commands include outlines and text for a tab`() {
        let commands = Toolbar.displayCommands(tabs: [Tab(viewportHeight: 500)], activeIndex: 0, addressBar: "", isAddressBarFocused: false)
        #expect(commands.contains { $0 is DrawOutline })
        #expect(commands.contains { $0 is DrawText })
    }
}
