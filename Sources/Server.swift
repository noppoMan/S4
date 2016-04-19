public protocol Server {
    func serve(_ responder: Responder, on host: String, at port: Int) throws
}

extension Server {
    public func serve(responder: Responder, at port: Int) throws {
        try self.serve(responder, on: "0.0.0.0", at: port)
    }
}
