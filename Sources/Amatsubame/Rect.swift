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

    func contains(_ point: Point) -> Bool {
        point.x >= left && point.x < right && point.y >= top && point.y < bottom
    }
}
