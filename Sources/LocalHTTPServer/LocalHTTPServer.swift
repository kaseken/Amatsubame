import Foundation
import Network

public final class LocalHTTPServer: @unchecked Sendable {
    public struct Request {
        public let method: String
        public let path: String
        public let headers: [String: String]
        public let body: String
    }

    public struct Response {
        public let status: Int
        public let reason: String
        public let contentType: String
        public let body: String

        public init(
            status: Int = 200,
            reason: String = "OK",
            contentType: String = "text/html; charset=utf-8",
            body: String,
        ) {
            self.status = status
            self.reason = reason
            self.contentType = contentType
            self.body = body
        }
    }

    enum ServerError: Error {
        case noPort
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "LocalHTTPServer")
    private let handler: @Sendable (Request) -> Response
    private let lock = NSLock()
    private var receivedRequests: [Request] = []
    private var didResumeStart = false

    public init(port: UInt16? = nil, handler: @escaping @Sendable (Request) -> Response) throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        if let port, let endpointPort = NWEndpoint.Port(rawValue: port) {
            listener = try NWListener(using: parameters, on: endpointPort)
        } else {
            listener = try NWListener(using: parameters)
        }
        self.handler = handler
    }

    public var requests: [Request] {
        lock.lock()
        defer { lock.unlock() }
        return receivedRequests
    }

    public func start() async throws -> UInt16 {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        return try await withCheckedThrowingContinuation { continuation in
            listener.stateUpdateHandler = { [weak self] state in
                guard let self, !didResumeStart else { return }
                switch state {
                case .ready:
                    if let port = listener.port?.rawValue {
                        didResumeStart = true
                        continuation.resume(returning: port)
                    } else {
                        didResumeStart = true
                        continuation.resume(throwing: ServerError.noPort)
                    }
                case let .failed(error):
                    didResumeStart = true
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }
    }

    public func stop() {
        listener.cancel()
    }

    private func handle(_ connection: NWConnection) {
        let box = ConnectionBox(connection)
        connection.start(queue: queue)
        receive(box, buffer: Data())
    }

    private func receive(_ box: ConnectionBox, buffer: Data) {
        box.connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var accumulated = buffer
            if let data { accumulated.append(data) }
            if let request = parseRequest(accumulated) {
                respond(to: request, on: box)
            } else if isComplete || error != nil {
                box.connection.cancel()
            } else {
                receive(box, buffer: accumulated)
            }
        }
    }

    private func parseRequest(_ data: Data) -> Request? {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        guard let headerText = String(data: data.subdata(in: data.startIndex ..< headerEnd.lowerBound), encoding: .utf8)
        else { return nil }
        let lines = headerText.components(separatedBy: "\r\n")
        let requestParts = (lines.first ?? "").split(separator: " ")
        guard requestParts.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            headers[key] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }

        let bodyData = data.subdata(in: headerEnd.upperBound ..< data.endIndex)
        let contentLength = headers["content-length"].flatMap { Int($0) } ?? 0
        guard bodyData.count >= contentLength else { return nil }

        return Request(
            method: String(requestParts[0]),
            path: String(requestParts[1]),
            headers: headers,
            body: String(data: bodyData.prefix(contentLength), encoding: .utf8) ?? "",
        )
    }

    private func respond(to request: Request, on box: ConnectionBox) {
        lock.lock()
        receivedRequests.append(request)
        lock.unlock()

        let response = handler(request)
        let bodyData = Data(response.body.utf8)
        let head =
            "HTTP/1.1 \(response.status) \(response.reason)\r\n"
                + "Content-Length: \(bodyData.count)\r\n"
                + "Content-Type: \(response.contentType)\r\n"
                + "Connection: close\r\n\r\n"
        var responseData = Data(head.utf8)
        responseData.append(bodyData)
        box.connection.send(content: responseData, completion: .contentProcessed { _ in
            box.connection.cancel()
        })
    }
}

private final class ConnectionBox: @unchecked Sendable {
    let connection: NWConnection

    init(_ connection: NWConnection) {
        self.connection = connection
    }
}
