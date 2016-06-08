public protocol RequestParser {
    func parse(from stream: Stream) throws -> Request
}
