public protocol ResponseParser {
    func parse(_ data: Data) throws -> Response?
}
