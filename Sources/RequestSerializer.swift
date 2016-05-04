public protocol RequestSerializer {
    func serialize(_ request: Request, to stream: Stream) throws
}
