public struct Request: Message {
    public var method: Method
    public var uri: URI
    public var version: Version
    public var headers: Headers
    public var body: Body
    public var cookies: [String: String]
    public var storage: [String: Any]

    public init(method: Method, uri: URI, version: Version, headers: Headers, body: Body, cookies: [String: String]) {
        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.cookies = cookies
        self.storage = [:]
    }
}

public protocol RequestInitializable {
    init(request: Request)
}

public protocol RequestRepresentable {
    var request: Request { get }
}

public protocol RequestConvertible: RequestInitializable, RequestRepresentable {}

extension Request {
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Data = [], cookies: [String: String] = [:]) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .buffer(body),
            cookies: cookies
        )

        self.headers["Content-Length"] += body.count.description
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Stream, cookies: [String: String] = [:]) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .receiver(body),
            cookies: cookies
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: (Stream) throws -> Void, cookies: [String: String] = [:]) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .sender(body),
            cookies: cookies
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }
}
