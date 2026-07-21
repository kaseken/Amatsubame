@testable import Amatsubame
import Testing

struct RectTests {
    private let rect = Rect(x: 10, y: 20, width: 30, height: 40)

    @Test func `edges derive from origin and size`() {
        #expect(rect.left == 10)
        #expect(rect.top == 20)
        #expect(rect.right == 40)
        #expect(rect.bottom == 60)
    }

    @Test func `contains includes the top-left edge`() {
        #expect(rect.contains(Point(x: 10, y: 20)))
    }

    @Test func `contains excludes the bottom-right edge`() {
        #expect(!rect.contains(Point(x: 40, y: 20)))
        #expect(!rect.contains(Point(x: 10, y: 60)))
    }

    @Test func `contains accepts an interior point and rejects an exterior one`() {
        #expect(rect.contains(Point(x: 39, y: 59)))
        #expect(!rect.contains(Point(x: 5, y: 25)))
    }
}
