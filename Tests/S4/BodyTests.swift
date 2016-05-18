import XCTest
@testable import S4

class BodyTests: XCTestCase {
    static var allTests : [(String, (BodyTests) -> () throws -> Void)] {
        return [
           ("testSender", testSender),
           ("testReceiver", testReceiver),
           ("testBuffer", testBuffer),
           ("testAsyncReceiver", testAsyncReceiver),
           ("testAsyncSender", testAsyncSender),
           ("testThrowInconvertibleType", testThrowInconvertibleType),
        ]
    }

    let data: Data = [0x00, 0x01, 0x02, 0x03]

    func testSender() {
        let sender = Body.sender { stream in
            try stream.send(self.data)
        }

        testBodyProperties(sender)
    }
    
    func testAsyncSender() {
        let sender = Body.asyncSender { stream, completion in
            stream.send(self.data) { closure in
                completion {
                    try closure()
                }
            }
        }
        testAsyncBodyProperties(sender)
    }

    func testReceiver() {
        let drain = Drain(for: self.data)
        let receiver = Body.receiver(drain)

        testBodyProperties(receiver)
    }
    
    func testAsyncReceiver() {
        let drain = AsyncDrain(for: self.data)
        let receiver = Body.asyncReceiver(drain)
        
        testAsyncBodyProperties(receiver)
    }

    func testBuffer() {
        let buffer = Body.buffer(self.data)

        testBodyProperties(buffer)
    }
    
    func testThrowInconvertibleType(){
        let sender = Body.sender { stream in
            try stream.send(self.data)
        }
        
        let drain = Drain(for: self.data)
        let receiver = Body.receiver(drain)
        
        let tasks: [[((Void) -> Void) -> Void]] = [sender, receiver].map { body in
            var body = body
            var tasks: [((Void) -> Void) -> Void] = []
            
            tasks.append({ next in
                body.becomeAsyncSender {
                    do {
                        try $0()
                    } catch BodyError.inconvertibleType {
                        next()
                    } catch {
                        XCTFail("Incorrect error type")
                    }
                }
            })
            
            tasks.append({ next in
                body.becomeAsyncReceiver {
                    do {
                        try $0()
                    } catch BodyError.inconvertibleType {
                        next()
                    } catch {
                        XCTFail("Incorrect error type")
                    }
                }
            })
            
            return tasks
        }
        
        waitForExpectations(delay: 1, withDescription: "testThrowInconvertibleType") { done in
            XCTestCase.series(tasks: tasks.flatMap { $0 }) {
                done()
            }
        }
    }

    private func testBodyProperties(_ body: Body) {
        var bodyForBuffer = body
        var bodyForReceiver = body
        var bodyForSender = body

        XCTAssert(data == (try! bodyForBuffer.becomeBuffer()), "Garbled buffer bytes")
        switch bodyForBuffer {
        case .buffer(let d):
            XCTAssert(data == d, "Garbled buffer bytes")
        default:
            XCTFail("Incorrect type")
        }

        bodyForReceiver.forceReopenDrain()
        let receiverDrain = Drain(for: try! bodyForReceiver.becomeReceiver())
        XCTAssert(data == receiverDrain.data, "Garbled receiver bytes")
        switch bodyForReceiver {
        case .receiver(let stream):
            bodyForReceiver.forceReopenDrain()
            let receiverDrain = Drain(for: stream)
            XCTAssert(data == receiverDrain.data, "Garbed receiver bytes")
        default:
            XCTFail("Incorrect type")
        }


        let senderDrain = Drain()
        bodyForReceiver.forceReopenDrain()
        do {
            try bodyForSender.becomeSender()(senderDrain)

        } catch {
            XCTFail("Drain threw error \(error)")
        }
        XCTAssert(data == senderDrain.data, "Garbled sender bytes")

        switch bodyForSender {
        case .sender(let closure):
            let senderDrain = Drain()
            bodyForReceiver.forceReopenDrain()
            do {
                try closure(senderDrain)
            } catch {
                XCTFail("Drain threw error \(error)")
            }
            XCTAssert(data == senderDrain.data, "Garbed sender bytes")
        default:
            XCTFail("Incorrect type")
        }
    }
    
    private func testAsyncBodyProperties(_ body: Body) {
        var bodyForAsyncBuffer = body
        var bodyForAsyncReceiver = body
        var bodyForAsyncSender = body
        
        waitForExpectations(delay: 1, withDescription: "testAsyncBodyProperties") { done in
            let asyncBufferTask: ((Void) -> Void) -> Void = { callback in
                bodyForAsyncBuffer.asyncBecomeBuffer {
                    let (bodyForAsyncBuffer, d) = try! $0()
                    XCTAssert(self.data == d, "Garbled buffer bytes")
                    switch bodyForAsyncBuffer {
                    case .buffer(let d):
                        XCTAssert(self.data == d, "Garbled buffer bytes")
                        callback()
                    default:
                        XCTFail("Incorrect type")
                    }
                }
            }
            
            let asyncReceiverTask: ((Void) -> Void) -> Void = { callback in
                
                bodyForAsyncReceiver.becomeAsyncReceiver {
                    var (bodyForAsyncReceiver, receiver) = try! $0()
                    var tasks: [((Void) -> Void) -> Void] = []
                    
                    tasks.append({ [unowned self] next in
                        
                        bodyForAsyncReceiver.forceReopenAsyncDrain {
                            _ = AsyncDrain(for: receiver) {
                                try! XCTAssert(self.data == $0().data, "Garbled buffer bytes")
                                next()
                            }
                        }
                    })
                    
                    tasks.append({ [unowned self] next in
                        bodyForAsyncReceiver.forceReopenAsyncDrain {
                            switch bodyForAsyncReceiver {
                            case .asyncReceiver(let receiver):
                                _ = AsyncDrain(for: receiver) {
                                    try! XCTAssert(self.data == $0().data, "Garbled buffer bytes")
                                    next()
                                }
                            default:
                                XCTFail("Incorrect type")
                            }
                        }
                    })
                    
                    XCTestCase.series(tasks: tasks) {
                        callback()
                    }
                }
            }

            let asyncSenderTask: ((Void) -> Void) -> Void = { callback in
                bodyForAsyncSender.becomeAsyncSender {
                    let (bodyForAsyncSender, sender) = try! $0()
                    var tasks: [((Void) -> Void) -> Void] = []
                    
                    tasks.append({ [unowned self] next in
                        bodyForAsyncReceiver.forceReopenAsyncDrain {
                            let drain = AsyncDrain()
                            sender(drain) {
                                do {
                                    try $0()
                                    XCTAssert(self.data == drain.data, "Garbled buffer bytes")
                                    next()
                                } catch {
                                    XCTFail("AsyncDrain threw error \(error)")
                                }
                            }
                        }
                    })
                    
                    tasks.append({ [unowned self] next in
                        bodyForAsyncReceiver.forceReopenAsyncDrain {
                            switch bodyForAsyncSender {
                            case .asyncSender(let sender):
                                let drain = AsyncDrain()
                                sender(drain) {
                                    do {
                                        try $0()
                                        XCTAssert(self.data == drain.data, "Garbled buffer bytes")
                                        next()
                                    } catch {
                                        XCTFail("AsyncDrain threw error \(error)")
                                    }
                                }
                            default:
                                XCTFail("Incorrect type")
                            }
                        }
                    })
                    
                    XCTestCase.series(tasks: tasks) {
                        callback()
                    }
                    
                }
            }
            
            let tasks = [asyncBufferTask, asyncReceiverTask, asyncSenderTask]
            
            XCTestCase.series(tasks: tasks) {
                done()
            }
        }
    }
}

extension Body {
    mutating func forceReopenDrain() {
        if let drain = (try! self.becomeReceiver()) as? Drain {
            drain.closed = false
        }
    }
    
    mutating func forceReopenAsyncDrain(completion: (Void) -> Void) {
        self.becomeAsyncReceiver {
            let (_, stream) = try! $0()
            let drain = stream as! AsyncDrain
            drain.closed = false
            completion()
        }
    }
}
