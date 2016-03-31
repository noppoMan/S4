public protocol Server {
    func serve(responder: Responder, on host: Host, at port: Port) throws
}
