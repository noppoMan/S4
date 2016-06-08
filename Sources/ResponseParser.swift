public protocol ResponseParser {
    func parse(from stream: Stream) throws -> Response
}
