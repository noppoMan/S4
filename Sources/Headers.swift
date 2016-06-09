public struct Headers {
    public var headers: [CaseInsensitiveString: String]
    public var cookies: Set<String>

    public init(_ headers: [CaseInsensitiveString: String]) {
        self.headers = headers
        self.cookies = []
    }
}

extension Headers: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (CaseInsensitiveString, String)...) {
        var headers: [CaseInsensitiveString: String] = [:]
        var cookies: Set<String> = []

        for (key, value) in elements {
            if key == "set-cookie" {
                cookies.insert(value)
            } else {
                headers[key] = value
            }
        }

        self.headers = headers
        self.cookies = cookies
    }
}

extension Headers: Sequence {
    #if swift(>=3.0)
    public func makeIterator() -> DictionaryIterator<CaseInsensitiveString, String> {
        return headers.makeIterator()
    }
    #else
    public func generate() -> DictionaryGenerator<CaseInsensitiveString, String> {
        return headers.generate()
    }
    #endif

    public var count: Int {
        return headers.count
    }

    public var isEmpty: Bool {
        return headers.isEmpty
    }

    public subscript(field: CaseInsensitiveStringRepresentable) -> String? {
        get {
            return headers[field.caseInsensitiveString]
        }

        set(header) {
            headers[field.caseInsensitiveString] = header
        }
    }
}
