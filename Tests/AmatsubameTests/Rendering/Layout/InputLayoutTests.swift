@testable import Amatsubame
import Testing

private func layoutControls(_ html: String) -> (tree: HTMLNode, controls: [FormControlTarget]) {
    let tree = HTMLParser(html).parse()
    let styled = style(tree, rules: sortedByCascade(defaultStyleRules))
    return (tree, formControlTargets(for: layoutDocument(styled)))
}

struct InputLayoutTests {
    @Test func `input is a fixed-width field and the button fits its label`() throws {
        let (_, controls) = layoutControls("<form action=/x><input name=q><button>Go</button></form>")
        #expect(controls.count == 2)
        #expect(controls.map(\.isButton) == [false, true])
        let input = try #require(controls.first { !$0.isButton })
        let button = try #require(controls.first { $0.isButton })
        #expect(input.rect.width == inputWidth)
        #expect(button.rect.width < inputWidth)
    }

    @Test func `control paths resolve back to their input and button nodes`() {
        let (tree, controls) = layoutControls("<form action=/x><input name=q><button>Go</button></form>")
        for control in controls {
            guard case let .element(tag, _, _)? = tree.node(at: control.nodePath) else {
                Issue.record("control path \(control.nodePath) did not resolve to an element")
                continue
            }
            #expect(tag == (control.isButton ? "button" : "input"))
        }
    }
}
