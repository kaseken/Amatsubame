import Foundation

@main
struct Amatsubame {
    static func main() async {
        let args = CommandLine.arguments
        guard args.count >= 2 else {
            fputs("Usage: Amatsubame <url>\n", stderr)
            exit(1)
        }
        do {
            let url = try BrowserURL(args[1])
            let body = try await request(url)
            show(body)
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }
}

func stripTags(_ body: String) -> String {
    var result = ""
    var inTag = false
    for ch in body {
        switch ch {
        case "<": inTag = true
        case ">": inTag = false
        default: if !inTag { result.append(ch) }
        }
    }
    return result
}

func show(_ body: String) {
    print(stripTags(body))
}
