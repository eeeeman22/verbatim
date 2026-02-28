import Foundation

/// Provides expected IPA pronunciations for English words
/// Uses a subset of CMU Pronouncing Dictionary converted to IPA
class PronunciationDictionary {
    
    static let shared = PronunciationDictionary()
    
    // MARK: - Properties
    private var dictionary: [String: String] = [:]
    
    // MARK: - Initialization
    private init() {
        loadBuiltInDictionary()
    }
    
    // MARK: - Public Methods
    
    /// Look up the IPA pronunciation for a word
    func lookup(_ word: String) -> String? {
        let normalizedWord = word.lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespaces)
        
        return dictionary[normalizedWord]
    }
    
    /// Check if a word exists in the dictionary
    func contains(_ word: String) -> Bool {
        lookup(word) != nil
    }
    
    /// Add a custom pronunciation
    func addPronunciation(word: String, ipa: String) {
        dictionary[word.lowercased()] = ipa
    }
    
    // MARK: - Private Methods
    
    private func loadBuiltInDictionary() {
        // Built-in dictionary with common words
        // In production, this would load from a bundled file (CMU dict converted to IPA)
        dictionary = [
            // Common test words for SLP
            "rabbit": "/ɹ æ b ɪ t/",
            "red": "/ɹ ɛ d/",
            "run": "/ɹ ʌ n/",
            "rain": "/ɹ eɪ n/",
            "road": "/ɹ oʊ d/",
            "rope": "/ɹ oʊ p/",
            "room": "/ɹ u m/",
            "rock": "/ɹ ɑ k/",
            
            "look": "/l ʊ k/",
            "like": "/l aɪ k/",
            "love": "/l ʌ v/",
            "lamp": "/l æ m p/",
            "little": "/l ɪ t əl/",
            "letter": "/l ɛ t ɚ/",
            
            "see": "/s i/",
            "say": "/s eɪ/",
            "sun": "/s ʌ n/",
            "soap": "/s oʊ p/",
            "sock": "/s ɑ k/",
            "saw": "/s ɔ/",
            "said": "/s ɛ d/",
            "some": "/s ʌ m/",
            "same": "/s eɪ m/",
            "sit": "/s ɪ t/",
            "set": "/s ɛ t/",
            "side": "/s aɪ d/",
            "song": "/s ɔ ŋ/",
            "soon": "/s u n/",
            
            "zoo": "/z u/",
            "zero": "/z ɪ ɹ oʊ/",
            "zebra": "/z i b ɹ ə/",
            
            "ship": "/ʃ ɪ p/",
            "shoe": "/ʃ u/",
            "shop": "/ʃ ɑ p/",
            "show": "/ʃ oʊ/",
            
            "think": "/θ ɪ ŋ k/",
            "thumb": "/θ ʌ m/",
            "three": "/θ ɹ i/",
            "this": "/ð ɪ s/",
            "that": "/ð æ t/",
            "the": "/ð ə/",
            "them": "/ð ɛ m/",
            "then": "/ð ɛ n/",
            "there": "/ð ɛ ɹ/",
            
            "cat": "/k æ t/",
            "car": "/k ɑ ɹ/",
            "cup": "/k ʌ p/",
            "key": "/k i/",
            "kick": "/k ɪ k/",
            "come": "/k ʌ m/",
            "cake": "/k eɪ k/",
            "cool": "/k u l/",
            
            "go": "/ɡ oʊ/",
            "get": "/ɡ ɛ t/",
            "give": "/ɡ ɪ v/",
            "good": "/ɡ ʊ d/",
            "game": "/ɡ eɪ m/",
            "girl": "/ɡ ɝ l/",
            "goat": "/ɡ oʊ t/",
            
            "fence": "/f ɛ n s/",
            "fish": "/f ɪ ʃ/",
            "five": "/f aɪ v/",
            "food": "/f u d/",
            "fun": "/f ʌ n/",
            "four": "/f ɔ ɹ/",
            "fast": "/f æ s t/",
            
            "very": "/v ɛ ɹ i/",
            "van": "/v æ n/",
            "vine": "/v aɪ n/",
            
            "bird": "/b ɝ d/",
            "big": "/b ɪ ɡ/",
            "ball": "/b ɔ l/",
            "bed": "/b ɛ d/",
            "book": "/b ʊ k/",
            "box": "/b ɑ k s/",
            "boy": "/b ɔɪ/",
            "blue": "/b l u/",
            
            "pig": "/p ɪ ɡ/",
            "pen": "/p ɛ n/",
            "put": "/p ʊ t/",
            "play": "/p l eɪ/",
            "please": "/p l i z/",
            
            "dog": "/d ɔ ɡ/",
            "day": "/d eɪ/",
            "down": "/d aʊ n/",
            "door": "/d ɔ ɹ/",
            
            "toy": "/t ɔɪ/",
            "top": "/t ɑ p/",
            "two": "/t u/",
            "time": "/t aɪ m/",
            "tree": "/t ɹ i/",
            
            "man": "/m æ n/",
            "mom": "/m ɑ m/",
            "my": "/m aɪ/",
            "more": "/m ɔ ɹ/",
            "make": "/m eɪ k/",
            
            "no": "/n oʊ/",
            "new": "/n u/",
            "name": "/n eɪ m/",
            "nice": "/n aɪ s/",
            "night": "/n aɪ t/",
            
            "sing": "/s ɪ ŋ/",
            "ring": "/ɹ ɪ ŋ/",
            "thing": "/θ ɪ ŋ/",
            "king": "/k ɪ ŋ/",
            
            "yes": "/j ɛ s/",
            "you": "/j u/",
            "yellow": "/j ɛ l oʊ/",
            "young": "/j ʌ ŋ/",
            
            "with": "/w ɪ θ/",
            "want": "/w ɑ n t/",
            "water": "/w ɔ t ɚ/",
            "what": "/w ʌ t/",
            "when": "/w ɛ n/",
            "where": "/w ɛ ɹ/",
            "why": "/w aɪ/",
            "white": "/w aɪ t/",
            
            "house": "/h aʊ s/",
            "her": "/h ɝ/",
            "him": "/h ɪ m/",
            "help": "/h ɛ l p/",
            "home": "/h oʊ m/",
            "happy": "/h æ p i/",
            
            "chair": "/tʃ ɛ ɹ/",
            "cheese": "/tʃ i z/",
            "child": "/tʃ aɪ l d/",
            "children": "/tʃ ɪ l d ɹ ən/",
            "chocolate": "/tʃ ɑ k l ɪ t/",
            
            "jump": "/dʒ ʌ m p/",
            "juice": "/dʒ u s/",
            "just": "/dʒ ʌ s t/",
            
            // Common phrases and function words
            "a": "/ə/",
            "an": "/æ n/",
            "and": "/æ n d/",
            "or": "/ɔ ɹ/",
            "but": "/b ʌ t/",
            "is": "/ɪ z/",
            "are": "/ɑ ɹ/",
            "was": "/w ʌ z/",
            "were": "/w ɝ/",
            "be": "/b i/",
            "been": "/b ɪ n/",
            "being": "/b i ɪ ŋ/",
            "have": "/h æ v/",
            "has": "/h æ z/",
            "had": "/h æ d/",
            "do": "/d u/",
            "does": "/d ʌ z/",
            "did": "/d ɪ d/",
            "will": "/w ɪ l/",
            "would": "/w ʊ d/",
            "could": "/k ʊ d/",
            "should": "/ʃ ʊ d/",
            "can": "/k æ n/",
            "may": "/m eɪ/",
            "might": "/m aɪ t/",
            "must": "/m ʌ s t/",
            "shall": "/ʃ æ l/",
            
            "i": "/aɪ/",
            "me": "/m i/",
            "he": "/h i/",
            "she": "/ʃ i/",
            "it": "/ɪ t/",
            "we": "/w i/",
            "they": "/ð eɪ/",
            
            "hopped": "/h ɑ p t/",
            "over": "/oʊ v ɚ/",
            "under": "/ʌ n d ɚ/",
            "in": "/ɪ n/",
            "on": "/ɑ n/",
            "at": "/æ t/",
            "to": "/t u/",
            "from": "/f ɹ ʌ m/",
            "of": "/ʌ v/",
            "for": "/f ɔ ɹ/",
        ]
    }
    
    // MARK: - ARPAbet to IPA Conversion
    
    /// Convert ARPAbet notation (used by CMU dict) to IPA
    static func arpabetToIPA(_ arpabet: String) -> String {
        let arpabetToIPAMap: [String: String] = [
            "AA": "ɑ", "AE": "æ", "AH": "ʌ", "AO": "ɔ", "AW": "aʊ",
            "AX": "ə", "AXR": "ɚ", "AY": "aɪ", "EH": "ɛ", "ER": "ɝ",
            "EY": "eɪ", "IH": "ɪ", "IX": "ɨ", "IY": "i", "OW": "oʊ",
            "OY": "ɔɪ", "UH": "ʊ", "UW": "u", "UX": "ʉ",
            
            "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "DX": "ɾ",
            "EL": "l̩", "EM": "m̩", "EN": "n̩", "F": "f", "G": "ɡ",
            "HH": "h", "JH": "dʒ", "K": "k", "L": "l", "M": "m",
            "N": "n", "NG": "ŋ", "NX": "ɾ̃", "P": "p", "Q": "ʔ",
            "R": "ɹ", "S": "s", "SH": "ʃ", "T": "t", "TH": "θ",
            "V": "v", "W": "w", "WH": "ʍ", "Y": "j", "Z": "z",
            "ZH": "ʒ"
        ]
        
        var result = ""
        let phonemes = arpabet.split(separator: " ")
        
        for phoneme in phonemes {
            // Remove stress markers (0, 1, 2)
            let cleaned = String(phoneme).replacingOccurrences(of: "[0-2]", with: "", options: .regularExpression)
            if let ipa = arpabetToIPAMap[cleaned] {
                result += ipa + " "
            }
        }
        
        return "/\(result.trimmingCharacters(in: .whitespaces))/"
    }
}
