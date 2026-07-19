enum Layout {
    static let canvasWidth = 800.0
    static let canvasHeight = 600.0
    static let horizontalStep = 13.0
    static let verticalStep = 18.0
    static let scrollStep = 100.0
}

struct DisplayItem {
    let x: Double
    let y: Double
    let c: Character
}

func layout(_ text: String) -> [DisplayItem] {
    var displayList: [DisplayItem] = []
    var cursorX = Layout.horizontalStep
    var cursorY = Layout.verticalStep
    for c in text {
        displayList.append(DisplayItem(x: cursorX, y: cursorY, c: c))
        cursorX += Layout.horizontalStep
        if cursorX >= Layout.canvasWidth - Layout.horizontalStep {
            cursorY += Layout.verticalStep
            cursorX = Layout.horizontalStep
        }
    }
    return displayList
}
