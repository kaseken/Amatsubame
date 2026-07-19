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
            guard let url = URL(string: args[1]) else {
                fputs("Error: invalid URL\n", stderr)
                exit(1)
            }
            let body = try await HTTPClient().request(url)
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
