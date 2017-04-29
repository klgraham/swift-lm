

struct swift_lm {

    var text = "Hello, World!"
}

//protocol LanguageModel {
//    /**
//     Trains the language model on a corpus of text.
//     
//     - parameters:
//     - corpus: The text the model will be trained on. Must be a String array. Each sentence starts with "\<s\>" and ends with "\<\/s\>"
//     */
//    mutating func train(on corpus: [String])
//    
//    /**
//     Computes the conditional probability that a given text string occurs given
//     that the text's context exists.
//     
//     - returns:
//     A float representing P(text | context)
//     
//     - parameters:
//     - text: The text we wish to know the probability of
//     - context: The context that the text is in relation to. Can be nil.
//     */
//    func prob(of text: String, given context: [String]?) -> Float
//    
//    func dump()
//}


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
