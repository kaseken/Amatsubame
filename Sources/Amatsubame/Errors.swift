enum BrowserError: Error {
    case invalidURL(String)
    case connectionFailed(String)
    case decodingError
}
