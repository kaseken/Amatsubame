@testable import Amatsubame
import Testing

struct LayoutTests {
    @Test func `document layout reports a positive height for content`() {
        let box = layoutDocument(style(parse("hello"), rules: sortedByCascade(defaultStyleRules)))
        #expect(box.height > 0)
    }
}
