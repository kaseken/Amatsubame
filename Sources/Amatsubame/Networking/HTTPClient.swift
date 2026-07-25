import Foundation

struct HTTPClient {
    func request(_ url: URL, method: String = "GET", body: String? = nil) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = Data(body.utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let responseBody = String(data: data, encoding: .utf8) else {
            throw Error.decodingFailed
        }
        return responseBody
    }

    enum Error: Swift.Error {
        case decodingFailed
    }
}
