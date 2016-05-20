public struct Request: Message {
    public var method: Method
    public var uri: URI
    public var version: Version
    public var headers: Headers
    public var body: Body
    public var storage: [String: Any]

    public init(method: Method, uri: URI, version: Version, headers: Headers, body: Body) {
        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.storage = [:]
    }
}

extension Request {
    public var cookies: [String: String] {
        guard let string = headers["cookie"].first else {
            return [:]
        }

        var cookies: [String : String] = [:]

        let tokens = string.characters.split(separator: ";")

        for token in tokens {
            let cookieTokens = token.split(separator: "=", maxSplits: 1)

            guard cookieTokens.count == 2 else {
                continue
            }

            let name = String(cookieTokens[0])
            let value = String(cookieTokens[1])

            cookies[name] = value
        }
        
        return cookies
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
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Data = []) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .buffer(body)
        )

        self.headers["Content-Length"] += body.count.description
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Stream) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .receiver(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: (Stream) throws -> Void) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: .sender(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }
}
