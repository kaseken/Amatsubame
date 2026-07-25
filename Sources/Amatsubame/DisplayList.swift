import AppKit

func displayCommands(for box: LayoutBox) -> [DisplayCommand] {
    switch box {
    case let .block(node, frame, children):
        let background = backgroundCommand(for: node, frame: frame)
        return (background.map { [$0] } ?? []) + children.flatMap(displayCommands)
    case let .inline(node, frame, words):
        let background = backgroundCommand(for: node, frame: frame)
        let texts = words.map { DrawText(x: $0.x, y: $0.y, text: $0.text, font: $0.font, color: $0.color) }
        return (background.map { [$0] } ?? []) + texts
    }
}

private func backgroundCommand(for node: StyledNode, frame: BoxFrame) -> DisplayCommand? {
    guard case .element = node.node,
          let background = node.style["background-color"], background != "transparent"
    else { return nil }
    return DrawRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height, color: color(for: background))
}
