/// A single lexical token produced from an HTML body.
enum Token: Equatable {
    /// Run of text between tags.
    case text(String)
    /// Tag body without the angle brackets, e.g. `b` or `/b`.
    case tag(String)
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
            tokens.append(.tag(buffer))
            buffer = ""
        default:
            buffer.append(ch)
        }
    }
    if !inTag, !buffer.isEmpty { tokens.append(.text(buffer)) }
    return tokens
}
