/**
    Represents the body of the HTTP message.

    An HTTP message body contains the bytes of data that
    are transmitted immediately following the headers.

    - buffer:        Simplest type of HTTP message body.
                     Represents a `Data` object containing
                     a byte array.

    - receiver:      Contains a `Stream` that can be drained
                     in chunks to access the body's data.

    - sender:        Contains a closure that accepts a `Stream`
                     object to which the body's data should be sent.
 
    - asyncReceiver: Contains a `AsyncStream` that can be drained
                     in chunks to access the body's data.
 
    - asyncSender:   Contains a closure that accepts a `AsyncStream`
                     object to which the body's data should be sent.
 
*/
public enum Body {
    case buffer(Data)
    case receiver(Stream)
    case sender(Stream throws -> Void)
    case asyncReceiver(AsyncStream)
    case asyncSender((AsyncStream, (Void throws -> Void) -> Void) -> Void)
}

public enum BodyError: ErrorProtocol {
    case inconvertibleType
}

extension Body {
    /**
        Converts the body's contents into a `Data` buffer.

        If the body is a receiver or sender type,
        it will be drained.
    */
    public mutating func becomeBuffer(timingOut deadline: Double = .never) throws -> Data {
        switch self {
        case .buffer(let data):
            return data
        case .receiver(let receiver):
            let data = Drain(for: receiver, timingOut: deadline).data
            self = .buffer(data)
            return data
        case .sender(let sender):
            let drain = Drain()
            try sender(drain)
            let data = drain.data

            self = .buffer(data)
            return data
        default:
            throw BodyError.inconvertibleType
        }
    }

    ///Returns true if body is case `buffer`
    public var isBuffer: Bool {
        switch self {
        case .buffer: return true
        default: return false
        }
    }

    /**
        Converts the body's contents into a `Stream`
        that can be received in chunks.
    */
    public mutating func becomeReceiver() throws -> Stream {
        switch self {
        case .receiver(let stream):
            return stream
        case .buffer(let data):
            let stream = Drain(for: data)
            self = .receiver(stream)
            return stream
        case .sender(let sender):
            let stream = Drain()
            try sender(stream)
            self = .receiver(stream)
            return stream
        default:
            throw BodyError.inconvertibleType
        }
    }

    ///Returns true if body is case `receiver`
    public var isReceiver: Bool {
        switch self {
        case .receiver: return true
        default: return false
        }
    }

    /**
        Converts the body's contents into a closure
        that accepts a `Stream`.
    */
    public mutating func becomeSender(timingOut deadline: Double = .never) -> (Stream throws -> Void) {
        switch self {
        case .buffer(let data):
            let closure: (Stream throws -> Void) = { sender in
                try sender.send(data, timingOut: deadline)
            }
            self = .sender(closure)
            return closure
        case .receiver(let receiver):
            let closure: (Stream throws -> Void) = { sender in
                let data = Drain(for: receiver, timingOut: deadline).data
                try sender.send(data, timingOut: deadline)
            }
            self = .sender(closure)
            return closure
        case .sender(let sender):
            return sender
        default:
            let closure: (Stream throws -> Void) = { _ in
                throw BodyError.inconvertibleType
            }
            return closure
        }
    }

    ///Returns true if body is case `sender`
    public var isSender: Bool {
        switch self {
        case .sender: return true
        default: return false
        }
    }
}

extension Body {
    /**
     Converts the body's contents into a `Data` buffer asynchronously.
     
     If the body is a receiver, sender, asyncReceiver or asyncSender type,
     it will be drained.
     */
    public mutating func asyncBecomeBuffer(timingOut deadline: Double = .never, completion: (Void throws -> (Body, Data)) -> Void) {
        switch self {
        case .asyncReceiver(let stream):
            _ = AsyncDrain(for: stream, timingOut: deadline) { closure in
                completion {
                    let drain = try closure ()
                    self = .buffer(drain.data)
                    return (self, drain.data)
                }
            }
            
        case .asyncSender(let sender):
            let drain = AsyncDrain()
            sender(drain) { closure in
                completion {
                    try closure()
                    self = .buffer(drain.data)
                    return (self, drain.data)
                }
            }
        default:
            completion {
                let data = try self.becomeBuffer(timingOut: deadline)
                return (self, data)
            }
        }
    }
    
    ///Returns true if body is case `asyncReceiver`
    public var isAsyncReceiver: Bool {
        switch self {
        case .asyncReceiver: return true
        default: return false
        }
    }
    
    
    /**
     Converts the body's contents into a `AsyncStream`
     that can be received in chunks.
     */
    public mutating func becomeAsyncReceiver(completion: (Void throws -> (Body, AsyncStream)) -> Void) {
        switch self {
        case .asyncReceiver(let stream):
            completion {
                (self, stream)
            }
        case .buffer(let data):
            let stream = AsyncDrain(for: data)
            self = .asyncReceiver(stream)
            completion {
                (self, stream)
            }
        case .asyncSender(let sender):
            let stream = AsyncDrain()
            sender(stream) { closure in
                completion {
                    try closure()
                    self = .asyncReceiver(stream)
                    return (self, stream)
                }
            }
        default:
            completion {
                throw BodyError.inconvertibleType
            }
        }
    }
    
    /**
     Converts the body's contents into a closure
     that accepts a `AsyncStream`.
     */
    public mutating func becomeAsyncSender(timingOut deadline: Double = .never, completion: (Void throws -> (Body, ((AsyncStream, (Void throws -> Void) -> Void) -> Void))) -> Void) {
        
        switch self {
        case .buffer(let data):
            let closure: ((AsyncStream, (Void throws -> Void) -> Void) -> Void) = { sender, result in
                sender.send(data, timingOut: deadline) { closure in
                    result {
                        try closure()
                    }
                }
            }
            completion {
                self = .asyncSender(closure)
                return (self, closure)
            }
        case .asyncReceiver(let receiver):
            let closure: ((AsyncStream, (Void throws -> Void) -> Void) -> Void) = { sender, result in
                _ = AsyncDrain(for: receiver, timingOut: deadline) {
                    do {
                        let drain = try $0()
                        sender.send(drain.data, timingOut: deadline, completion: result)
                    } catch {
                        result {
                            throw error
                        }
                    }
                }
            }
            completion {
                self = .asyncSender(closure)
                return (self, closure)
            }
        case .asyncSender(let closure):
            completion {
                (self, closure)
            }
        default:
            completion {
                throw BodyError.inconvertibleType
            }
        }
    }
    
    ///Returns true if body is case `asyncSender`
    public var isAsyncSender: Bool {
        switch self {
        case .asyncSender: return true
        default: return false
        }
    }
}