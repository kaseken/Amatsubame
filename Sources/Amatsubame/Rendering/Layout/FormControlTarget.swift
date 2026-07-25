import AppKit

struct FormControlTarget {
    let rect: Rect
    let nodePath: NodePath
    let isButton: Bool
}

func formControlTargets(for box: LayoutBox) -> [FormControlTarget] {
    switch box {
    case let .block(_, _, children):
        children.flatMap(formControlTargets)
    case let .inline(_, _, _, formControls):
        formControls.map { control in
            FormControlTarget(
                rect: Rect(x: control.x, y: control.y, width: control.width, height: control.height),
                nodePath: control.nodePath,
                isButton: control.isButton,
            )
        }
    }
}
