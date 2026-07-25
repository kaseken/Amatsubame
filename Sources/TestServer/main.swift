import Foundation
import LocalHTTPServer

let port = CommandLine.arguments.dropFirst().first.flatMap { UInt16($0) } ?? 8000
let site = Site()

do {
    let server = try LocalHTTPServer(port: port) { site.handle($0) }
    Task {
        do {
            let boundPort = try await server.start()
            print("Test server running at http://127.0.0.1:\(boundPort)/")
        } catch {
            fputs("Failed to start server: \(error)\n", stderr)
            exit(1)
        }
    }
    dispatchMain()
} catch {
    fputs("Failed to start server: \(error)\n", stderr)
    exit(1)
}
