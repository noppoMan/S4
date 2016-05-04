public protocol ResponseSerializer {
    func serialize(_ response: Response, to stream: Stream) throws
}
