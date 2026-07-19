/// A single lexical token produced from an HTML body.
enum Token: Equatable {
    /// Run of text between tags.
    case text(String)
    /// A parsed tag, e.g. `<b>` or `</b>`.
    case tag(Tag)
}

/// An HTML tag. Recognized formatting tags get their own case; anything else is
/// preserved as ``other(_:)`` so the lexer stays independent of what layout styles.
enum Tag: Equatable {
    case boldOpen, boldClose
    case italicOpen, italicClose
    case smallOpen, smallClose
    case bigOpen, bigClose
    case lineBreak
    case paragraphOpen, paragraphClose
    case other(String)

    /// Parses a tag body (without angle brackets), e.g. `b` or `/b`.
    init(_ body: String) {
        switch body {
        case "b": self = .boldOpen
        case "/b": self = .boldClose
        case "i": self = .italicOpen
        case "/i": self = .italicClose
        case "small": self = .smallOpen
        case "/small": self = .smallClose
        case "big": self = .bigOpen
        case "/big": self = .bigClose
        case "br": self = .lineBreak
        case "p": self = .paragraphOpen
        case "/p": self = .paragraphClose
        default: self = .other(body)
        }
    }
}

/// Splits an HTML body into text and tag tokens.
///
/// Text between tags becomes ``Token/text(_:)``; the contents of `<...>` become
/// ``Token/tag(_:)``. Empty text runs are dropped, matching browser.engineering.
func lex(_ body: String) -> [Token] {
    var tokens: [Token] = []
    var buffer = ""
    var inTag = false
    for ch in body {
        switch ch {
        case "<":
            inTag = true
            if !buffer.isEmpty { tokens.append(.text(buffer)) }
            buffer = ""
        case ">":
            inTag = false
            tokens.append(.tag(Tag(buffer)))
            buffer = ""
        default:
            buffer.append(ch)
        }
    }
    if !inTag, !buffer.isEmpty { tokens.append(.text(buffer)) }
    return tokens
}
