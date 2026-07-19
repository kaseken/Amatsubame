import Foundation

struct HTTPClient {
    func request(_ url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let body = String(data: data, encoding: .utf8) else {
            throw Error.decodingFailed
        }
        return body
    }

    enum Error: Swift.Error {
        case decodingFailed
    }
}
