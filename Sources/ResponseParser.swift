public protocol ResponseParser {
    func parse(_ stream: Stream) throws -> Response
}
