@testable import Amatsubame
import Testing

struct LayoutTests {
    @Test func `first character at origin`() {
        let list = layout("A")
        #expect(list.count == 1)
        #expect(list[0].x == hstep)
        #expect(list[0].y == vstep)
        #expect(list[0].c == "A")
    }

    @Test func `one item per character`() {
        let text = "hello world"
        #expect(layout(text).count == text.count)
    }

    @Test func `x advances by H step`() {
        let list = layout("abc")
        #expect(list[0].x == hstep)
        #expect(list[1].x == hstep * 2)
        #expect(list[2].x == hstep * 3)
    }

    @Test func `wraps to next line`() throws {
        // Enough characters to exceed WIDTH - HSTEP and force a second row.
        let perRow = Int((width - hstep) / hstep)
        let list = layout(String(repeating: "x", count: perRow + 1))
        let wrapped = try #require(list.last)
        #expect(wrapped.x == hstep)
        #expect(wrapped.y == vstep * 2)
    }

    @Test func `empty text`() {
        #expect(layout("").isEmpty)
    }
}
