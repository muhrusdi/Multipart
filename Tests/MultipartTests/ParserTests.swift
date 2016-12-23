import Foundation
import XCTest
@testable import Multipart

class ParserTests: XCTestCase {
    static var allTests = [
        ("testInit", testInit),
        ("testPreamble", testPreamble),
        ("testPreambleWithFauxBoundaries", testPreambleWithFauxBoundaries),
    ]

    func testInit() {
        let parser = Parser(boundary: "foo")
        XCTAssertEqual(parser.boundary, "foo".bytes)
    }
    
    func testPreamble() throws {
        let parser = Parser(boundary: "foo")
        
        var preamble = ""
        preamble += "This is the preamble.  It is to be ignored, though it\n"
        preamble += "is a handy place for composition agents to include an\n"
        preamble += "explanatory note to non-MIME conformant readers.\n"
        preamble += "\n"
        
        var message = ""
        message += preamble
        message += "--foo--\n"
        
        let preambleExpectation = expectation(description: "preamble was parsed")
        
        parser.onPreamble = { parsedPreamble in
            XCTAssertEqual(parsedPreamble.string, preamble)
            preambleExpectation.fulfill()
        }
        
        try parser.parse(message.bytes)
        
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testPreambleWithFauxBoundaries() throws {
        let parser = Parser(boundary: "foo")
        
        var preamble = ""
        preamble += "This is the preamble.  It is to be ignored, though it\n"
        preamble += "is a handy --fooxo\n place for --bar\n composition agents to include an\n"
        preamble += "explanatory note to non-MIME conformant readers.\n"
        preamble += "\n"
        
        var message = ""
        message += preamble
        message += "--foo--\n"
        
        let preambleExpectation = expectation(description: "preamble was parsed")
        
        parser.onPreamble = { parsedPreamble in
            XCTAssertEqual(parsedPreamble.string, preamble)
            preambleExpectation.fulfill()
        }
        
        try parser.parse(message.bytes)
        
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testParts() throws {
        let parser = Parser(boundary: "foo")
        
        var preamble = ""
        preamble += "This is the preamble.  It is to be ignored, though it\n"
        preamble += "is a handy place for composition agents to include an\n"
        preamble += "explanatory note to non-MIME conformant readers.\n"
        preamble += "\n"
        
        let part1 = "testfoobar"
        
        var message = ""
        message += preamble
        message += "--foo\n"
        message += "\n"
        message += part1
        message += "--foo--\n"
        
        let partExpectation = expectation(description: "part was parsed")
        
        parser.onPart = { part in
            XCTAssertEqual(part.body.string, part1)
            partExpectation.fulfill()
        }
        
        try parser.parse(message.bytes)
        
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testHeaders() throws {
        let parser = Parser(boundary: "foo")
        
        let part1 = "testfoobar"
        
        var message = ""
        message += "preamble"
        message += "--foo\n"
        message += "key:  value\n"
        message += "foo:bar\n"
        message += "\n"
        message += part1
        message += "--foo--\n"
        
        let partExpectation = expectation(description: "part was parsed")
        
        parser.onPart = { part in
            XCTAssertEqual(part.body.string, part1)
            XCTAssertEqual(part.headers.count, 2)
            XCTAssertEqual(part.headers["key"], "value")
            XCTAssertEqual(part.headers["foo"], "bar")
            partExpectation.fulfill()
        }
        
        try parser.parse(message.bytes)
        
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testEpilogue() throws {
        let parser = Parser(boundary: "foo")
        
        let epilogue = "\nepliogue"
        
        var message = ""
        message += "preamble"
        message += "--foo\n"
        message += "\n"
        message += "part"
        message += "--foo--\n"
        message += epilogue
        
        let epilogueExpectation = expectation(description: "epilogue was parsed")
        
        parser.onEpilogue = { e in
            XCTAssertEqual(e.string, epilogue)
            epilogueExpectation.fulfill()
        }
        
        try parser.parse(message.bytes)
        
        // must call done since epilogue can go on forever
        try parser.finish()
        
        waitForExpectations(timeout: 0, handler: nil)
    }
}
