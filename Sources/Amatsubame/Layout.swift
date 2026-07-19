let width = 800.0
let height = 600.0
let hstep = 13.0
let vstep = 18.0
let scrollStep = 100.0

struct DisplayItem {
    let x: Double
    let y: Double
    let c: Character
}

func layout(_ text: String) -> [DisplayItem] {
    var displayList: [DisplayItem] = []
    var cursorX = hstep
    var cursorY = vstep
    for c in text {
        displayList.append(DisplayItem(x: cursorX, y: cursorY, c: c))
        cursorX += hstep
        if cursorX >= width - hstep {
            cursorY += vstep
            cursorX = hstep
        }
    }
    return displayList
}
