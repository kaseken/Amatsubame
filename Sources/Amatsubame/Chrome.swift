import AppKit

@MainActor
final class Chrome {
    enum Focus: Equatable {
        case none
        case addressBar
    }

    enum Action: Equatable {
        case none
        case newTab
        case selectTab(Int)
        case back
        case focusAddress
    }

    var focus: Focus = .none
    var addressBar = ""

    private let font = Fonts.get(size: 14, weight: .regular, italic: false)
    private let padding = 5.0
    private let tabWidth = 80.0

    private var fontHeight: Double {
        font.ascender + font.descent
    }

    private var tabBarBottom: Double {
        fontHeight + 2 * padding
    }

    private var urlBarTop: Double {
        tabBarBottom
    }

    var bottom: Double {
        tabBarBottom + fontHeight + 2 * padding
    }

    var newTabRect: Rect {
        Rect(x: padding, y: padding, width: font.width(of: "+") + 2 * padding, height: fontHeight)
    }

    private var tabsStart: Double {
        newTabRect.right + padding
    }

    func tabRect(_ index: Int) -> Rect {
        Rect(x: tabsStart + Double(index) * tabWidth, y: 0, width: tabWidth, height: tabBarBottom)
    }

    var backRect: Rect {
        Rect(x: padding, y: urlBarTop + padding, width: font.width(of: "<") + 2 * padding, height: fontHeight)
    }

    var addressRect: Rect {
        Rect(
            x: backRect.right + padding,
            y: urlBarTop + padding,
            width: Layout.canvasWidth - backRect.right - 2 * padding,
            height: fontHeight,
        )
    }

    func paint(tabs: [Tab], activeIndex: Int) -> [DisplayCommand] {
        var commands: [DisplayCommand] = [
            DrawRect(x: 0, y: 0, width: Layout.canvasWidth, height: bottom, color: .white),
            DrawLine(x1: 0, y1: bottom, x2: Layout.canvasWidth, y2: bottom, color: .black, thickness: 1),
        ]

        commands.append(outline(newTabRect))
        commands.append(label("+", in: newTabRect))

        for index in tabs.indices {
            let bounds = tabRect(index)
            commands.append(DrawLine(x1: bounds.left, y1: 0, x2: bounds.left, y2: bounds.bottom, color: .black, thickness: 1))
            commands.append(DrawLine(x1: bounds.right, y1: 0, x2: bounds.right, y2: bounds.bottom, color: .black, thickness: 1))
            commands.append(label("Tab \(index)", in: bounds))
            if index == activeIndex {
                commands.append(DrawLine(x1: 0, y1: bounds.bottom, x2: bounds.left, y2: bounds.bottom, color: .black, thickness: 1))
                commands.append(DrawLine(x1: bounds.right, y1: bounds.bottom, x2: Layout.canvasWidth, y2: bounds.bottom, color: .black, thickness: 1))
            }
        }

        commands.append(outline(backRect))
        commands.append(label("<", in: backRect))

        commands.append(outline(addressRect))
        if focus == .addressBar {
            commands.append(label(addressBar, in: addressRect))
            let cursorX = addressRect.left + padding + font.width(of: addressBar)
            commands.append(DrawLine(x1: cursorX, y1: addressRect.top, x2: cursorX, y2: addressRect.bottom, color: .red, thickness: 1))
        } else {
            let currentURL = tabs.indices.contains(activeIndex) ? (tabs[activeIndex].url?.absoluteString ?? "") : ""
            commands.append(label(currentURL, in: addressRect))
        }

        return commands
    }

    func click(x: Double, y: Double, tabCount: Int) -> Action {
        focus = .none
        if newTabRect.contains(x: x, y: y) { return .newTab }
        if backRect.contains(x: x, y: y) { return .back }
        if addressRect.contains(x: x, y: y) {
            focus = .addressBar
            addressBar = ""
            return .focusAddress
        }
        for index in 0 ..< tabCount where tabRect(index).contains(x: x, y: y) {
            return .selectTab(index)
        }
        return .none
    }

    func keypress(_ character: Character) {
        guard focus == .addressBar else { return }
        addressBar.append(character)
    }

    func backspace() {
        guard focus == .addressBar else { return }
        if !addressBar.isEmpty { addressBar.removeLast() }
    }

    func enter() -> URL? {
        defer { focus = .none }
        return URL(string: addressBar)
    }

    private func outline(_ rect: Rect) -> DisplayCommand {
        DrawOutline(x: rect.x, y: rect.y, width: rect.width, height: rect.height, color: .black, thickness: 1)
    }

    private func label(_ text: String, in rect: Rect) -> DisplayCommand {
        DrawText(x: rect.left + padding, y: rect.top, text: text, font: font, color: .black)
    }
}
