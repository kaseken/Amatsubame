@testable import Amatsubame
import Testing

private func styledTree(_ html: String, rules: [CSSRule] = sortedByCascade(defaultStyleRules)) -> StyledNode {
    style(parse(html), rules: rules)
}

private func firstText(_ node: StyledNode) -> StyledNode? {
    if case .text = node.node { return node }
    return node.children.lazy.compactMap(firstText).first
}

private func firstElement(_ node: StyledNode, tag: String) -> StyledNode? {
    if case let .element(nodeTag, _, _) = node.node, nodeTag == tag { return node }
    return node.children.lazy.compactMap { firstElement($0, tag: tag) }.first
}

struct StyleTests {
    @Test func `color inherits to descendant text`() throws {
        let text = try #require(firstText(styledTree(#"<p style="color:red">hi</p>"#)))
        #expect(text.style["color"] == "red")
    }

    @Test func `inline style overrides a matching rule`() throws {
        let text = try #require(firstText(styledTree(#"<a style="color:green">x</a>"#)))
        #expect(text.style["color"] == "green")
    }

    @Test func `descendant selector wins over tag selector via priority`() throws {
        let rules = sortedByCascade(CSSParser("div span { color: green; } span { color: red; }").parse())
        let text = try #require(firstText(styledTree("<div><span>hi</span></div>", rules: rules)))
        #expect(text.style["color"] == "green")
    }

    @Test func `percentage font-size resolves against the parent`() throws {
        let rules = sortedByCascade(CSSParser("div { font-size: 20px; } span { font-size: 50%; }").parse())
        let span = try #require(firstElement(styledTree("<div><span>hi</span></div>", rules: rules), tag: "span"))
        #expect(span.style["font-size"] == "10.0px")
    }
}
