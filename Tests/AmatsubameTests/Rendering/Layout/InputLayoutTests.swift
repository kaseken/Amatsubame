@testable import Amatsubame
import Testing

private func layoutControls(_ html: String) -> (tree: HTMLNode, controls: [FormControlTarget]) {
    let tree = HTMLParser(html).parse()
    let styled = style(tree, rules: sortedByCascade(defaultStyleRules))
    return (tree, formControlTargets(for: layoutDocument(styled)))
}

struct InputLayoutTests {
    @Test func `input and button lay out as fixed-width inline controls`() {
        let (_, controls) = layoutControls("<form action=/x><input name=q><button>Go</button></form>")
        #expect(controls.count == 2)
        #expect(controls.allSatisfy { $0.rect.width == inputWidth })
        #expect(controls.map(\.isButton) == [false, true])
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
