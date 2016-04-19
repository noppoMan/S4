public protocol AsyncServer {
    func serve(_ responder: AsyncResponder, on host: String, at port: Int) throws
}

extension AsyncServer {
    public func serve(_ responder: AsyncResponder, at port: Int) throws {
        try self.serve(responder, on: "0.0.0.0", at: port)
    }
}
