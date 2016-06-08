public protocol RequestParser {
    func parse(from stream: Stream, completion: @noescape (Request) -> Void) throws
}
