import AppKit

@main
struct Amatsubame {
    @MainActor
    static func main() {
        let args = CommandLine.arguments
        guard args.count >= 2 else {
            fputs("Usage: Amatsubame <url>\n", stderr)
            exit(1)
        }
        guard let url = URL(string: args[1]) else {
            fputs("Error: invalid URL\n", stderr)
            exit(1)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let browser = Browser()
        browser.load(url)
        app.activate(ignoringOtherApps: true)
        app.run()
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
