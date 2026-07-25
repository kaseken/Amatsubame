import AppKit

struct LinkTarget {
    let rect: Rect
    let href: String
}

func displayCommands(for box: LayoutBox) -> (commands: [DisplayCommand], links: [LinkTarget]) {
    switch box {
    case let .block(node, frame, children):
        let childResults = children.map(displayCommands)
        let background = backgroundCommand(for: node, frame: frame)
        return (
            (background.map { [$0] } ?? []) + childResults.flatMap(\.commands),
            childResults.flatMap(\.links),
        )
    case let .inline(node, frame, words):
        let texts = words.map { DrawText(x: $0.x, y: $0.y, text: $0.text, font: $0.font, color: $0.color) }
        let links = words.compactMap { word -> LinkTarget? in
            guard let href = word.href else { return nil }
            let rect = Rect(
                x: word.x,
                y: word.y,
                width: word.font.width(of: word.text),
                height: word.font.ascender + word.font.descent,
            )
            return LinkTarget(rect: rect, href: href)
        }
        let background = backgroundCommand(for: node, frame: frame)
        return ((background.map { [$0] } ?? []) + texts, links)
    }
}

private func backgroundCommand(for node: StyledNode, frame: BoxFrame) -> DisplayCommand? {
    guard case .element = node.node,
          let background = node.style["background-color"], background != "transparent"
    else { return nil }
    return DrawRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height, color: color(for: background))
}
