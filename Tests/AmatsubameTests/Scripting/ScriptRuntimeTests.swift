@testable import Amatsubame
import Testing

struct ScriptRuntimeTests {
    private func makeTree() -> HTMLNode {
        HTMLParser("<html><body><strong>hi</strong><input name=q value=Ada></body></html>").parse()
    }

    @Test func `querySelectorAll and getAttribute read from the document`() {
        let runtime = ScriptRuntime(document: makeTree())
        runtime.run("""
        var input = document.querySelectorAll('input')[0];
        document.querySelectorAll('strong')[0].innerHTML = input.getAttribute('name');
        """)
        #expect(runtime.document?.node(at: [0, 0]) == .element(tag: "strong", attributes: [:], children: [.text("q")]))
    }

    @Test func `innerHTML setter replaces a node's children`() {
        let runtime = ScriptRuntime(document: makeTree())
        runtime.run("document.querySelectorAll('strong')[0].innerHTML = 'bye';")
        #expect(runtime.document?.node(at: [0, 0]) == .element(tag: "strong", attributes: [:], children: [.text("bye")]))
    }

    @Test func `preventDefault makes dispatchEvent report the default is cancelled`() {
        let runtime = ScriptRuntime(document: makeTree())
        runtime.run("""
        document.querySelectorAll('input')[0].addEventListener('click', function (event) {
          event.preventDefault();
        });
        """)
        #expect(runtime.dispatchEvent(type: "click", at: [0, 1]) == false)
    }

    @Test func `a listener that does not prevent the default keeps it enabled`() {
        let runtime = ScriptRuntime(document: makeTree())
        runtime.run("document.querySelectorAll('input')[0].addEventListener('click', function () {});")
        #expect(runtime.dispatchEvent(type: "click", at: [0, 1]) == true)
    }

    @Test func `dispatching to an element with no listeners keeps the default enabled`() {
        let runtime = ScriptRuntime(document: makeTree())
        #expect(runtime.dispatchEvent(type: "click", at: [0, 1]) == true)
    }

    @Test func `an event listener can mutate the document via innerHTML`() {
        let runtime = ScriptRuntime(document: makeTree())
        runtime.run("""
        document.querySelectorAll('input')[0].addEventListener('click', function () {
          document.querySelectorAll('strong')[0].innerHTML = 'clicked';
        });
        """)
        _ = runtime.dispatchEvent(type: "click", at: [0, 1])
        #expect(runtime.document?.node(at: [0, 0]) == .element(
            tag: "strong", attributes: [:], children: [.text("clicked")],
        ))
    }
}
