struct Point {
    let x: Double
    let y: Double

    func offsetBy(dx: Double = 0, dy: Double = 0) -> Point {
        Point(x: x + dx, y: y + dy)
    }
}
