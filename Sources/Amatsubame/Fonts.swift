import AppKit

/// Cache key identifying a font by its size, weight, and slant.
private struct FontKey: Hashable {
    let size: Double
    let weight: NSFont.Weight
    let italic: Bool
}

/// Caches `NSFont` instances so identical (size, weight, italic) combinations are
/// only constructed once, mirroring the `FONTS` cache in browser.engineering.
@MainActor
enum Fonts {
    private static var cache: [FontKey: NSFont] = [:]

    static func get(size: Double, weight: NSFont.Weight, italic: Bool) -> NSFont {
        let key = FontKey(size: size, weight: weight, italic: italic)
        if let font = cache[key] { return font }
        var font = NSFont.systemFont(ofSize: size, weight: weight)
        if italic {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        cache[key] = font
        return font
    }
}

extension NSFont {
    /// Horizontal width of `text` when rendered in this font.
    func measure(_ text: String) -> Double {
        (text as NSString).size(withAttributes: [.font: self]).width
    }

    /// Distance from the baseline to the top of the font.
    var ascent: Double {
        ascender
    }

    /// Distance from the baseline to the bottom of the font (positive).
    var descent: Double {
        -descender
    }
}
