public struct Response: Message {
    public var version: Version
    public var status: Status
    public var headers: Headers
    public var cookieHeaders: Set<String>
    public var body: Body
    public var storage: [String: Any] = [:]

    public init(version: Version, status: Status, headers: Headers, cookieHeaders: Set<String>, body: Body) {
        self.version = version
        self.status = status
        self.headers = headers
        self.cookieHeaders = cookieHeaders
        self.body = body
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
    public init(status: Status = .ok, headers: Headers = [:], cookieHeaders: Set<String> = [], body: Data = []) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: cookieHeaders,
            body: .buffer(body)
        )

        self.headers["Content-Length"] = body.count.description
    }

    public init(status: Status = .ok, headers: Headers = [:], cookieHeaders: Set<String> = [], body: Stream) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: cookieHeaders,
            body: .receiver(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(status: Status = .ok, headers: Headers = [:], cookieHeaders: Set<String> = [], body: (SendingStream) throws -> Void) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: cookieHeaders,
            body: .sender(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(status: Status = .ok, headers: Headers = [:], cookieHeaders: Set<String> = [], body: AsyncStream) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: cookieHeaders,
            body: .asyncReceiver(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }

    public init(status: Status = .ok, headers: Headers = [:], cookieHeaders: Set<String> = [], body: (AsyncSendingStream, ((Void) throws -> Void) -> Void) -> Void) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: cookieHeaders,
            body: .asyncSender(body)
        )

        self.headers["Transfer-Encoding"] = "chunked"
    }
}
