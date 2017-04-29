
import Foundation

struct swift_lm {

    var text = "Hello, World!"
}

struct Constants {
    static let alphanumericChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890".characters)    
}

func loadCorpus(from path: String) -> [String] {
    var lines = [String]()
    
    if let streamReader = StreamReader(path: path) {
        defer {
            streamReader.close()
        }
        
        for line in streamReader {
            lines.append(line)
        }
    }
    
    return lines
}


func removeNonAlphanumericCharacters(from text: String) -> String {
    return String(text.characters.filter { Constants.alphanumericChars.contains($0) })
}

// split a string on \s, \n, \r, and \t and lowercase the text
func tokenize(_ text: String) -> [String] {
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    return words.flatMap { $0.components(separatedBy: "\t") }.map { removeNonAlphanumericCharacters(from: $0.lowercased()) }
}
    

func getStringIndex(at index: Int, of text: String) -> String.Index {
    return text.index(text.startIndex, offsetBy: index)
}

func getChar(at i: Int, from text: String) -> Character {
    return text[getStringIndex(at: i, of: text)]
}

func getSubstring(of text: String, from: Int, to: Int) -> String {
    var substring = ""
    
    for i in from..<to {
        substring += String(getChar(at: i, from: text))
    }
    return substring
}

// split string into two parts
// (1) substring from i to the end
// (2) substring from the start to i
func split(word: String, at index: Int) -> (String, String) {
    let prefix = getSubstring(of: word, from: 0, to: index)
    let suffix = getSubstring(of: word, from: index, to: word.characters.count)
    return (prefix, suffix)
}

// returns a new string, absent the character at specified index
func deleteChar(at i: Int, from text: String) -> String {
    var output = text
    output.remove(at: getStringIndex(at: i, of: text))
    return output
}


func swapChars(at i: Int, and j: Int, of text: String) -> String {
    assert(i < j, "Error: \(i) is not less than \(j)")
    
    let a = getChar(at: i, from: text)
    let b = getChar(at: j, from: text)
    
    return getSubstring(of: text, from: 0, to: i) + String(b) +
        getSubstring(of: text, from: (i + 1), to: j) + String(a) +
        getSubstring(of: text, from: (j + 1), to: text.characters.count)
}

func replaceChar(at i: Int, from text: String, with a: Character) -> String {
    return getSubstring(of: text, from: 0, to: i) + String(a) +
        getSubstring(of: text, from: (i+1), to: text.characters.count)
}

func insert(_ c: Character, into text: String, at index: Int) -> String {
    var output = text
    output.insert(c, at: getStringIndex(at: index, of: text))
    return output
}
