
import Foundation

struct Constants {
    static let alphanumericChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890".characters)
    
    static let letters = Set("abcdefghijklmnopqrstuvwxyz".characters)
}


func removeNonAlphanumericCharacters(from text: String) -> String {
    return String(text.characters.filter { Constants.alphanumericChars.contains($0) })
}

// split a string on \s, \n, \r, and \t and lowercase the text
func tokenize(_ text: String) -> [String] {
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    return words.flatMap { $0.components(separatedBy: "\t") }.map { removeNonAlphanumericCharacters(from: $0.lowercased()) }
}

func loadCorpus(from path: String) -> [String] {
    var words = [String]()
    
    if let streamReader = StreamReader(path: path) {
        defer {
            streamReader.close()
        }
        
        for line in streamReader {
            words.append(contentsOf: tokenize(line))
        }
    }
    
    return words
}

func getStringIndex(at index: Int, of text: String) -> String.Index {
    return text.index(text.startIndex, offsetBy: index)
}

func getChar(at i: Int, from text: String) -> Character? {
    if i < text.characters.count {
        return text[getStringIndex(at: i, of: text)]
    } else {
        return Optional.none
    }
}

func getSubstring(of text: String, from: Int, to: Int) -> String {
    var substring = ""
    
    for i in from..<to {
        if let c = getChar(at: i, from: text) {
            substring += String(c)
        }
    }
    
    return substring
}

// split string into two parts
// (1) substring from i to the end
// (2) substring from the start to i
func split(word: String, at index: Int) -> (String, String
    ) {
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
    
    return getSubstring(of: text, from: 0, to: i) + String(b!) +
        getSubstring(of: text, from: (i + 1), to: j) + String(a!) +
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

func countWordsIn(_ words: [String]) -> [String: Int] {
    var wordCounts = [String: Int]()
    
    for word in words {
        if let count = wordCounts[word] {
            wordCounts[word] = count + 1
        } else {
            wordCounts[word] = 1
        }
    }
    
    return wordCounts
}

struct UnigramModel {
    private var maxCorrections = 3
    private let wordCounts: [String: Int]
    
    init(corpus path: String) {
        let words = loadCorpus(from: path)
        wordCounts = countWordsIn(words)
    }
    
    func getFrequencyOf(_ word: String) -> Int {
        if let frequency = wordCounts[word] {
            return frequency
        } else {
            return 0
        }
    }
    
    func getWordCounts() -> [String: Int] {
        return wordCounts
    }
    
    mutating func setMaxCorrections(to n: Int) {
        maxCorrections = n
    }
    
    func vocabContains(_ word: String) -> Bool {
        if let _ = wordCounts[word] {
            return true
        } else {
            return false
        }
    }
    
    func getWordsOffByOneCharacter(from word: String) -> Set<String> {
        var edits = [String]()
        
        var splits = [(String, String)]()
        for i in 0...(word.characters.count) {
            splits.append(split(word: word, at: i))
        }
        
        for (left, right) in splits {
            if !right.isEmpty {
                // deletions
                edits.append(left + deleteChar(at: 0, from: right))
                
                // swap adjacent letters
                if right.characters.count > 1 {
                    edits.append(left + swapChars(at: 0, and: 1, of: right))
                }
                
                
                for letter in Constants.letters {
                    // insertions
                    edits.append(left + String(letter) + right)

                    // replacements
                    edits.append(left + replaceChar(at: 0, from: right, with: letter))
                }
            }
        }
        
        return Set(edits)
    }
    
    func getWordsOffByTwoCharacters(from word: String) -> Set<String> {
        var edits = [String]()
        
        for e1 in getWordsOffByOneCharacter(from: word) {
            for e2 in getWordsOffByOneCharacter(from: e1) {
                edits.append(e2)
            }
        }
        
        return Set(edits)
    }
    
    func generateCorrectionCandidates(of word: String) -> [String] {
        var candidates = [String]()
        
        let knownEdits1 = getWordsOffByOneCharacter(from: word).filter { vocabContains($0) }
        let knownEdits2 = getWordsOffByTwoCharacters(from: word).filter { vocabContains($0) }
        candidates.append(contentsOf: knownEdits1)
        candidates.append(contentsOf: knownEdits2)
        
        if vocabContains(word) {
            candidates.append(word)
        }
        
        return candidates
    }
    
    func getCorrectionsFor(_ word: String) -> [String] {
        let candidates = generateCorrectionCandidates(of: word)
        
        var wordProbabilities = [String: Float]()
        candidates.forEach { wordProbabilities[$0] = probabilityOf($0) }
        let topWords = wordProbabilities.sorted(by: >).map { $0.key }
        let n = min(maxCorrections, topWords.count)
        return Array(topWords.prefix(upTo: n))
    }
    
    var totalNumWords: Int {
        var sum = 0
        for count in wordCounts.values {
            sum += count
        }
        return sum
    }
    
    func probabilityOf(_ word: String) -> Float {
        if let count = wordCounts[word] {
            return Float(count) / Float(totalNumWords)
        } else {
            return 0
        }
    }
}

class SpellChecker {
    private var model: UnigramModel
    
    init(corpus: String, maxCorrections: Int) {
        model = UnigramModel(corpus: corpus)
        model.setMaxCorrections(to: maxCorrections)
    }
    
    convenience init(corpus: String) {
        self.init(corpus: corpus, maxCorrections: 3)
    }
    
    convenience init() {
        self.init(corpus: "data/big.txt")
    }
    
    func getCorrectionsFor(_ word: String) -> [String] {
        return model.getCorrectionsFor(word)
    }
}
