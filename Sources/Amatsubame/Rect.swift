struct Rect {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    var left: Double {
        x
    }

    var top: Double {
        y
    }

    var right: Double {
        x + width
    }

    var bottom: Double {
        y + height
    }

    func contains(x pointX: Double, y pointY: Double) -> Bool {
        pointX >= left && pointX < right && pointY >= top && pointY < bottom
    }
}
