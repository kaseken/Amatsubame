import AppKit

func color(for value: String?) -> NSColor {
    guard let value else { return .black }
    if value.hasPrefix("#") { return hexColor(value) ?? .black }
    return switch value {
    case "blue": .blue
    case "red": .red
    case "green": .green
    case "yellow": .yellow
    case "orange": .orange
    case "purple": .purple
    case "brown": .brown
    case "cyan": .cyan
    case "magenta": .magenta
    case "gray", "grey": .gray
    case "white": .white
    default: .black
    }
}

private func hexColor(_ value: String) -> NSColor? {
    let digits = value.dropFirst()
    guard digits.count == 6, let rgb = Int(digits, radix: 16) else { return nil }
    return NSColor(
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255,
        alpha: 1,
    )
}
