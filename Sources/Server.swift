public protocol Server {
    func serve(responder: Responder, on host: String, at port: Port) throws
}
