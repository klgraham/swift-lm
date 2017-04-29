import XCTest
@testable import swift_lm

class swift_lmTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        XCTAssertEqual(getChar(at: 3, from: "01234"), "3")
        XCTAssertEqual(getSubstring(of: "01234", from: 1, to: 3), "12")
        XCTAssert(split(word: "apple", at: 0) == ("", "apple"))
        XCTAssert(split(word: "apple", at: 2) == ("ap", "ple"))
        XCTAssertEqual(deleteChar(at: 3, from: "012345"), "01245")
        XCTAssertEqual(swapChars(at: 2, and: 5, of: "01234567"), "01534267")
        XCTAssertEqual(replaceChar(at: 3, from: "012345", with: "?"), "012?45")
        XCTAssertEqual(insert("$", into: "012345", at: 3), "012$345")
        
        XCTAssert(!loadCorpus(from: "Tests/swift-lmTests/test_corpus.txt").isEmpty)
        XCTAssert(loadCorpus(from: "Tests/swift-lmTests/test_corpus.txt").contains("unmanned"))
        
        XCTAssertEqual(removeNonAlphanumericCharacters(from: "asdf$5^qwerty"), "asdf5qwerty")
        XCTAssertEqual(tokenize("I like cheese.\nDo you?"), ["i", "like", "cheese", "do", "you"])
        XCTAssertEqual(countWordsIn(["i", "like", "like", "do", "do"]), ["like": 2, "do": 2, "i": 1])
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
