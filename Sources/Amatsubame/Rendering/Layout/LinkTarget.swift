import AppKit

struct LinkTarget {
    let rect: Rect
    let href: String
}

func linkTargets(for box: LayoutBox) -> [LinkTarget] {
    switch box {
    case let .block(_, _, children):
        children.flatMap(linkTargets)
    case let .inline(_, _, words, _):
        words.compactMap { word in
            guard let href = word.href else { return nil }
            let rect = Rect(
                x: word.x,
                y: word.y,
                width: word.font.width(of: word.text),
                height: word.font.ascender + word.font.descent,
            )
            return LinkTarget(rect: rect, href: href)
        }
    }
}
