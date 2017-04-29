/*: An N-Gram Language Model
 
 
 */

import Foundation

/**
 An enum for strings whose syntactic content is to separate or demarcate text.
 */
enum SyntaxMarkers: String {
    // start of sentence marker
    case start = "<s>"
    
    // end of sentence marker
    case end = "</s>"
    case comma = ","
    case period = "."
    case space = " "
}

/**
 Types of n-grams
 */
enum NGramType {
    case character
    case word
}

/**
 Size of n-grams
 */
enum NGramSize: Int {
    case unigram = 1
    case bigram = 2
    case trigram = 3
    case quadrigram = 4
    case pentagram = 5
}

/**
 An n-gram object
 */
class NGram: CustomStringConvertible {
    // The members of the n-gram. The oldest member of the n-gram is the leftmost member.
    let elements: [String]
    
    init(_ elements: [String]) {
        self.elements = elements
    }
    
    var description: String {
        return "\(elements)"
    }
}

extension NGram: Hashable {
    var hashValue: Int {
        var result = 17
        for element in elements {
            result = 31 &* result &+ element.hashValue
        }
        return result
    }

    static func ==(lhs: NGram, rhs: NGram) -> Bool {
        return lhs.elements == rhs.elements
    }
}

/**
 Specfication for a language model
 */
protocol LanguageModel {
    /**
     Trains the language model on a corpus of text.
     
     - parameters:
        - corpus: The text the model will be trained on. Must be a String array. Each sentence starts with "\<s\>" and ends with "\<\/s\>"
    */
    mutating func train(on corpus: [String])
    
    /**
     Computes the conditional probability that a given text string occurs given
     that the text's context exists.
     
     - returns:
     A float representing P(text | context)
     
     - parameters:
        - text: The text we wish to know the probability of
        - context: The context that the text is in relation to. Can be nil.
    */
    func prob(of text: String, given context: [String]?) -> Float
    
    func dump()
}

/** 
 N-gram sequence model
 */
class NGramModel: LanguageModel {
    private let nGramType: NGramType
    private let nGramSize: NGramSize
    
    /* if N is the vocab size, then unigrams counts are O(N) storage,
     bigram counts are O(N^2), trigrams are O(N^3) storage. Since it's
     not all pair or all triplets, the space complexity for bigram and trigram 
     counts are a little better than what's written above.
     */
    private var totalCount: Int
    private var unigramCounts: [String: Int]
    private var nGramCounts: [NGram: Int]
    private var nMinus1GramCounts: [NGram: Int]
    
    init(type: NGramType, size: NGramSize) {
        self.nGramType = type
        self.nGramSize = size
        self.unigramCounts = [String: Int]()
        
        self.nGramCounts = [NGram: Int]()
        self.nMinus1GramCounts = [NGram: Int]()
        
        self.totalCount = 0
    }
    
    /* 
     Trains in a single pass through the data, O(n), where
     n is the number of tokens in the corpus. n <= vocab size
     */ 
    func train(on corpus: [String]) {
        for line in corpus {
            // Can also just do this at the start, provided EOS tokens are included as
            // unigrams
            var previousUnigrams = [String](repeating: SyntaxMarkers.start.rawValue, count: nGramSize.rawValue - 1)
            
            for (index, token) in line.components(separatedBy: SyntaxMarkers.space.rawValue).enumerated() {
                totalCount += 1
                let unigram = token.lowercased()
                
                if let count = unigramCounts[unigram.lowercased()] {
                    unigramCounts.updateValue(count + 1, forKey: unigram)
                } else {
                    unigramCounts[unigram] = 1
                }
                
                if index > 0 {
                    var context = previousUnigrams
                    context.append(unigram)
                    let smallerContext = Array(context.dropFirst())
                    
                    let ngram = NGram(context)
                    
                    if nGramSize != .bigram {
                        let nMinus1Gram = NGram(smallerContext)
                    
                        if let count = nMinus1GramCounts[nMinus1Gram] {
                            nMinus1GramCounts.updateValue(count + 1, forKey: nMinus1Gram)
                        } else {
                            nMinus1GramCounts[nMinus1Gram] = 1
                        }
                    }
                    
                    if let count = nGramCounts[ngram] {
                        nGramCounts.updateValue(count + 1, forKey: ngram)
                    } else {
                        nGramCounts[ngram] = 1
                    }
                    
                    for n in 0..<(previousUnigrams.count-1) {
                        previousUnigrams[n] = previousUnigrams[n+1]
                    }
                    previousUnigrams[previousUnigrams.count-1] = unigram
                }
            }
        }
    }
    
    // context = [..., prevPrevPrev, prevPrev, prev]
    func prob(of text: String, given context: [String]? = nil) -> Float {
        guard let history = context else {
            guard let tokenCount = unigramCounts[text] else {
                return 0
            }
            return Float(tokenCount) / Float(totalCount)
        }
        
        assert(history.count != nGramSize.rawValue, "Size of context must be \(nGramSize.rawValue)")
        
        var ngramContents = history
        ngramContents.append(text)
        
        guard let ngramCount = nGramCounts[NGram(ngramContents)] else {
            return 0
        }
        
        var count: Float
        
        if nGramSize != .bigram {
            guard let contextCount = nMinus1GramCounts[NGram(history)] else {
                return 0
            }
            count = Float(contextCount)
        } else {
            guard let contextCount = unigramCounts[history[0]] else {
                return 0
            }
            count = Float(contextCount)
        }
        
        return Float(ngramCount) / count
    }
    
    func dump() {
        print("N-gram distribution")
        for (ngram, count) in nGramCounts {
            print("\(ngram): \(count)")
        }
        
        print("\n(N-1)-gram distribution")
        for (ngram, count) in nMinus1GramCounts {
            print("\(ngram): \(count)")
        }
    }
}

let drSeuss = ["<s> I am Sam </s>", "<s> Sam I am </s>", "<s> I do not like green eggs and ham </s>"]

var bigramModel = NGramModel(type: .word, size: .bigram)
bigramModel.train(on: drSeuss)

bigramModel.prob(of: "i", given: [SyntaxMarkers.start.rawValue]) == 2.0/3.0
bigramModel.prob(of: "do", given: ["i"]) == 1.0/3.0
bigramModel.prob(of: "sam", given: ["am"]) == 0.5
bigramModel.prob(of: "sam", given: [SyntaxMarkers.start.rawValue]) == 1.0/3.0
bigramModel.dump()

var trigramModel = NGramModel(type: .word, size: .trigram)
trigramModel.train(on: drSeuss)
trigramModel.prob(of: "am", given: ["sam", "i"]) == 1
trigramModel.prob(of: "am", given: [SyntaxMarkers.start.rawValue, "i"]) == 0.5

/*
 To use this, just need to prepend/append the start and end characters onto each line.
 Can then just read a text file line by line and build a token trigram model.
 */

