import Testing

@testable import Amatsubame

@Suite struct LayoutTests {
    @Test func firstCharacterAtOrigin() {
        let list = layout("A")
        #expect(list.count == 1)
        #expect(list[0].x == hstep)
        #expect(list[0].y == vstep)
        #expect(list[0].c == "A")
    }

    @Test func oneItemPerCharacter() {
        let text = "hello world"
        #expect(layout(text).count == text.count)
    }

    @Test func xAdvancesByHStep() {
        let list = layout("abc")
        #expect(list[0].x == hstep)
        #expect(list[1].x == hstep * 2)
        #expect(list[2].x == hstep * 3)
    }

    @Test func wrapsToNextLine() {
        // Enough characters to exceed WIDTH - HSTEP and force a second row.
        let perRow = Int((width - hstep) / hstep)
        let list = layout(String(repeating: "x", count: perRow + 1))
        let wrapped = list.last!
        #expect(wrapped.x == hstep)
        #expect(wrapped.y == vstep * 2)
    }

    @Test func emptyText() {
        #expect(layout("").isEmpty)
    }
}
