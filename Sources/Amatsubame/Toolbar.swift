import AppKit

@MainActor
enum Toolbar {
    enum Action: Equatable {
        case none
        case newTab
        case selectTab(Int)
        case back
        case focusAddress
    }

    private static let font = Fonts.get(size: 14, weight: .regular, italic: false)
    private static let padding = 5.0
    private static let tabWidth = 80.0

    private static var fontHeight: Double {
        font.ascender + font.descent
    }

    private static var tabBarBottom: Double {
        fontHeight + 2 * padding
    }

    private static var urlBarTop: Double {
        tabBarBottom
    }

    static var height: Double {
        tabBarBottom + fontHeight + 2 * padding
    }

    private static var newTabRect: Rect {
        Rect(x: padding, y: padding, width: font.width(of: "+") + 2 * padding, height: fontHeight)
    }

    private static var tabsStart: Double {
        newTabRect.right + padding
    }

    private static func tabRect(_ index: Int) -> Rect {
        Rect(x: tabsStart + Double(index) * tabWidth, y: 0, width: tabWidth, height: tabBarBottom)
    }

    private static var backRect: Rect {
        Rect(x: padding, y: urlBarTop + padding, width: font.width(of: "<") + 2 * padding, height: fontHeight)
    }

    private static var addressRect: Rect {
        Rect(
            x: backRect.right + padding,
            y: urlBarTop + padding,
            width: Layout.canvasWidth - backRect.right - 2 * padding,
            height: fontHeight,
        )
    }

    static func displayCommands(tabs: [Tab], activeIndex: Int, addressBar: String, isAddressBarFocused: Bool) -> [DisplayCommand] {
        var commands: [DisplayCommand] = [
            DrawRect(x: 0, y: 0, width: Layout.canvasWidth, height: height, color: .white),
            DrawLine(x1: 0, y1: height, x2: Layout.canvasWidth, y2: height, color: .black, thickness: 1),
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
        if isAddressBarFocused {
            commands.append(label(addressBar, in: addressRect))
            let cursorX = addressRect.left + padding + font.width(of: addressBar)
            commands.append(DrawLine(x1: cursorX, y1: addressRect.top, x2: cursorX, y2: addressRect.bottom, color: .red, thickness: 1))
        } else {
            let currentURL = tabs.indices.contains(activeIndex) ? (tabs[activeIndex].url?.absoluteString ?? "") : ""
            commands.append(label(currentURL, in: addressRect))
        }

        return commands
    }

    static func action(at point: Point, tabCount: Int) -> Action {
        if newTabRect.contains(point) { return .newTab }
        if backRect.contains(point) { return .back }
        if addressRect.contains(point) { return .focusAddress }
        for index in 0 ..< tabCount where tabRect(index).contains(point) {
            return .selectTab(index)
        }
        return .none
    }

    private static func outline(_ rect: Rect) -> DisplayCommand {
        DrawRectOutline(x: rect.x, y: rect.y, width: rect.width, height: rect.height, color: .black, thickness: 1)
    }

    private static func label(_ text: String, in rect: Rect) -> DisplayCommand {
        DrawText(x: rect.left + padding, y: rect.top, text: text, font: font, color: .black)
    }
}
