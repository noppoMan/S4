public protocol RequestParser {
    func parse(_ data: Data) throws -> Request?
}
