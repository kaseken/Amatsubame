import Foundation
import Network

private enum ConnectionError: Error {
    case decodingFailed
    case invalidResponse(String)
    case cancelled
}

func request(_ url: URL) async throws -> String {
    let params: NWParameters = url.scheme == .https ? .tls : .tcp
    let connection = NWConnection(
        host: NWEndpoint.Host(url.host),
        port: NWEndpoint.Port(integerLiteral: UInt16(url.port)),
        using: params,
    )
    let rawRequest = "GET \(url.path) HTTP/1.0\r\nHost: \(url.host)\r\n\r\n"

    let responseData: Data = try await withCheckedThrowingContinuation { continuation in
        let fetcher = Fetcher(connection: connection, request: rawRequest, continuation: continuation)
        connection.stateUpdateHandler = { fetcher.handle($0) }
        connection.start(queue: .global())
    }

    guard let raw = String(data: responseData, encoding: .utf8) else {
        throw ConnectionError.decodingFailed
    }
    guard let sep = raw.range(of: "\r\n\r\n") else {
        throw ConnectionError.invalidResponse("no header/body separator in response")
    }
    return String(raw[sep.upperBound...])
}

/// Bridges NWConnection callbacks to async/await.
/// @unchecked Sendable is safe here because all mutable state is protected by `lock`.
private final class Fetcher: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private var done = false
    private var continuation: CheckedContinuation<Data, Error>?
    private let connection: NWConnection
    private let request: String

    init(connection: NWConnection, request: String, continuation: CheckedContinuation<Data, Error>) {
        self.connection = connection
        self.request = request
        self.continuation = continuation
    }

    func handle(_ state: NWConnection.State) {
        switch state {
        case .ready:
            connection.send(content: request.data(using: .utf8), completion: .contentProcessed { error in
                if let error { self.finish(.failure(error)); return }
                self.receive()
            })
        case let .failed(error):
            finish(.failure(error))
        case .cancelled:
            finish(.failure(ConnectionError.cancelled))
        default:
            break
        }
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data { self.lock.withLock { self.buffer.append(data) } }
            if let error {
                self.finish(.failure(error))
            } else if isComplete {
                self.finish(.success(self.lock.withLock { self.buffer }))
            } else {
                self.receive()
            }
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        lock.withLock {
            guard !done else { return }
            done = true
            connection.stateUpdateHandler = nil
            connection.cancel()
            switch result {
            case let .success(d): continuation?.resume(returning: d)
            case let .failure(e): continuation?.resume(throwing: e)
            }
            continuation = nil
        }
    }
}
