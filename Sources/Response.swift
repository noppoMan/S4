public struct Response: Message {
    public var version: Version
    public var status: Status
    public var headers: Headers
    public var body: Body
    public var cookies: Cookies
    public var storage: [String: Any]

    public init(version: Version, status: Status, headers: Headers, body: Body, cookies: Cookies) {
        self.version = version
        self.status = status
        self.headers = headers
        self.body = body
        self.cookies = cookies
        self.storage = [:]
    }
}

public protocol ResponseInitializable {
    init(response: Response)
}

public protocol ResponseRepresentable {
    var response: Response { get }
}

public protocol ResponseConvertible: ResponseInitializable, ResponseRepresentable {}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], body: Data = [], cookies: Cookies) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            body: .buffer(body),
            cookies: cookies
        )

        self.headers["Content-Length"] += body.count.description
    }

    public init(status: Status = .ok, headers: Headers = [:], body: Stream, cookies: Cookies) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            body: .receiver(body),
            cookies: cookies
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(status: Status = .ok, headers: Headers = [:], body: (SendingStream) throws -> Void, cookies: Cookies) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            body: .sender(body),
            cookies: cookies
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }
    
    public init(status: Status = .ok, headers: Headers = [:], body: AsyncStream) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            body: .asyncReceiver(body)
        )
        
        self.headers["Transfer-Encoding"] = "chunked"
    }
    
    public init(status: Status = .ok, headers: Headers = [:], body: (AsyncSendingStream, ((Void) throws -> Void) -> Void) -> Void) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            body: .asyncSender(body)
        )
        
        self.headers["Transfer-Encoding"] = "chunked"
    }
}
