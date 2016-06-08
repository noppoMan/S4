public protocol RequestParser {
    func parse(_ stream: Stream) throws -> Request
}
