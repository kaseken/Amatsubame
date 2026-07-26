import AppKit

protocol DisplayCommand {
    var top: Double { get }
    var bottom: Double { get }
    func draw(scrollY: Double)
}

struct DrawText: DisplayCommand {
    let x: Double
    let y: Double
    let text: String
    let font: NSFont
    let color: NSColor

    var top: Double {
        y
    }

    var bottom: Double {
        y + font.ascender + font.descent
    }

    func draw(scrollY: Double) {
        let point = NSPoint(x: x, y: y - scrollY)
        (text as NSString).draw(at: point, withAttributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }
}

struct DrawRect: DisplayCommand {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let color: NSColor

    var top: Double {
        y
    }

    var bottom: Double {
        y + height
    }

    func draw(scrollY: Double) {
        color.setFill()
        NSRect(x: x, y: y - scrollY, width: width, height: height).fill()
    }
}

struct DrawLine: DisplayCommand {
    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double
    let color: NSColor
    let thickness: Double

    var top: Double {
        min(y1, y2)
    }

    var bottom: Double {
        max(y1, y2)
    }

    func draw(scrollY: Double) {
        let path = NSBezierPath()
        path.lineWidth = thickness
        path.move(to: NSPoint(x: x1, y: y1 - scrollY))
        path.line(to: NSPoint(x: x2, y: y2 - scrollY))
        color.setStroke()
        path.stroke()
    }
}

struct DrawRectOutline: DisplayCommand {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let color: NSColor
    let thickness: Double

    var top: Double {
        y
    }

    var bottom: Double {
        y + height
    }

    func draw(scrollY: Double) {
        let path = NSBezierPath(rect: NSRect(x: x, y: y - scrollY, width: width, height: height))
        path.lineWidth = thickness
        color.setStroke()
        path.stroke()
    }
}

func displayCommands(for box: LayoutBox, focusedInputPath: NodePath? = nil) -> [DisplayCommand] {
    switch box {
    case let .block(node, frame, children):
        let background = backgroundCommand(for: node, frame: frame)
        return (background.map { [$0] } ?? []) + children.flatMap { displayCommands(for: $0, focusedInputPath: focusedInputPath) }
    case let .inline(node, frame, words, formControls):
        let background = backgroundCommand(for: node, frame: frame)
        let texts = words.map { DrawText(x: $0.x, y: $0.y, text: $0.text, font: $0.font, color: $0.color) }
        let formControlDrawing = formControls.flatMap { formControlCommands(for: $0, focused: $0.nodePath == focusedInputPath) }
        return (background.map { [$0] } ?? []) + texts + formControlDrawing
    }
}

private let formControlBorderColor = NSColor(white: 0.55, alpha: 1)

private func formControlCommands(for control: PositionedFormControl, focused: Bool) -> [DisplayCommand] {
    let background = DrawRect(
        x: control.x, y: control.y, width: control.width, height: control.height, color: control.backgroundColor,
    )
    let border = DrawRectOutline(
        x: control.x, y: control.y, width: control.width, height: control.height,
        color: formControlBorderColor, thickness: 1,
    )
    let textHeight = control.font.ascender + control.font.descent
    let labelX = control.isButton
        ? control.x + (control.width - control.font.width(of: control.text)) / 2
        : control.x + formControlHorizontalPadding
    let labelY = control.y + (control.height - textHeight) / 2
    let label = DrawText(x: labelX, y: labelY, text: control.text, font: control.font, color: control.color)
    let cursor: [DisplayCommand] = focused ? [caretCommand(for: control)] : []
    return [background, border, label] + cursor
}

private func caretCommand(for control: PositionedFormControl) -> DisplayCommand {
    let caretX = control.x + formControlHorizontalPadding + control.font.width(of: control.text)
    let textHeight = control.font.ascender + control.font.descent
    let caretTop = control.y + (control.height - textHeight) / 2
    return DrawLine(
        x1: caretX, y1: caretTop, x2: caretX, y2: caretTop + textHeight, color: .black, thickness: 1,
    )
}

private func backgroundCommand(for node: StyledNode, frame: BoxFrame) -> DisplayCommand? {
    guard case .element = node.node,
          let background = node.style["background-color"], background != "transparent"
    else { return nil }
    return DrawRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height, color: color(for: background))
}
