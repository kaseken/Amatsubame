import AppKit

/// Builds `NSFont` instances for a given size, weight, and slant.
///
/// The book caches fonts because Tkinter font objects are expensive to create and
/// measure; AppKit already interns system fonts cheaply, so no cache is needed.
enum Fonts {
    static func get(size: Double, weight: NSFont.Weight, italic: Bool) -> NSFont {
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        return italic
            ? NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            : font
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
