public protocol ResponseParser {
    func parse(from stream: Stream, completion: @noescape (Response) -> Void) throws
}
