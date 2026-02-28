import Foundation

/// Analyzes phonetic transcriptions to identify error patterns
class ErrorPatternAnalyzer {
    
    static let shared = ErrorPatternAnalyzer()
    
    // MARK: - Phoneme Categories
    
    private let liquids = Set(["ɹ", "l"])
    private let glides = Set(["w", "j"])
    private let velars = Set(["k", "ɡ", "ŋ"])
    private let alveolars = Set(["t", "d", "n", "s", "z", "l"])
    private let fricatives = Set(["f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "h"])
    private let stops = Set(["p", "b", "t", "d", "k", "ɡ"])
    private let affricates = Set(["tʃ", "dʒ"])
    private let nasals = Set(["m", "n", "ŋ"])
    private let voiced = Set(["b", "d", "ɡ", "v", "ð", "z", "ʒ", "dʒ", "m", "n", "ŋ", "l", "ɹ", "w", "j"])
    private let voiceless = Set(["p", "t", "k", "f", "θ", "s", "ʃ", "tʃ", "h"])
    
    // MARK: - Analysis
    
    /// Analyze the difference between expected and produced phonetics
    func analyzeErrors(expected: String, produced: String) -> [SuggestedError] {
        let expectedPhonemes = parsePhonemes(expected)
        let producedPhonemes = parsePhonemes(produced)
        
        var errors: [SuggestedError] = []
        
        // Align phonemes and find substitutions
        let aligned = alignPhonemes(expected: expectedPhonemes, produced: producedPhonemes)
        
        for (exp, prod) in aligned {
            if let exp = exp, let prod = prod, exp != prod {
                if let pattern = identifyPattern(expected: exp, produced: prod) {
                    errors.append(SuggestedError(
                        target: exp,
                        produced: prod,
                        pattern: pattern
                    ))
                }
            } else if let exp = exp, prod == nil {
                // Deletion
                if isWordFinal(phoneme: exp, in: expectedPhonemes) {
                    errors.append(SuggestedError(
                        target: exp,
                        produced: "∅",
                        pattern: .finalConsonantDeletion
                    ))
                } else if isWordInitial(phoneme: exp, in: expectedPhonemes) {
                    errors.append(SuggestedError(
                        target: exp,
                        produced: "∅",
                        pattern: .initialConsonantDeletion
                    ))
                }
            }
        }
        
        return errors
    }
    
    /// Identify the specific error pattern from a substitution
    func identifyPattern(expected: String, produced: String) -> ErrorPattern? {
        // Gliding: liquid → glide
        if liquids.contains(expected) && glides.contains(produced) {
            return .gliding
        }
        
        // Frontal Lisp: /s/, /z/ → /θ/, /ð/
        if (expected == "s" && produced == "θ") || (expected == "z" && produced == "ð") {
            return .frontalLisp
        }
        
        // Lateral Lisp: would need acoustic analysis, but can suggest if /s/ or /z/ sounds unusual
        
        // Stopping: fricative → stop
        if fricatives.contains(expected) && stops.contains(produced) {
            return .stopping
        }
        
        // Fronting: velar → alveolar
        if velars.contains(expected) && alveolars.contains(produced) {
            return .fronting
        }
        
        // Backing: alveolar → velar
        if alveolars.contains(expected) && velars.contains(produced) {
            return .backing
        }
        
        // Deaffrication: affricate → fricative
        if affricates.contains(expected) && fricatives.contains(produced) {
            return .deaffrication
        }
        
        // Affrication: fricative → affricate
        if fricatives.contains(expected) && affricates.contains(produced) {
            return .affrication
        }
        
        // Voicing: voiceless → voiced
        if voiceless.contains(expected) && voiced.contains(produced) {
            // Check if same manner of articulation
            if sameMannerOfArticulation(expected, produced) {
                return .voicing
            }
        }
        
        // Devoicing: voiced → voiceless
        if voiced.contains(expected) && voiceless.contains(produced) {
            if sameMannerOfArticulation(expected, produced) {
                return .devoicing
            }
        }
        
        // Nasalization
        if !nasals.contains(expected) && nasals.contains(produced) {
            return .nasalization
        }
        
        // Denasalization
        if nasals.contains(expected) && !nasals.contains(produced) {
            return .denasalization
        }
        
        // If we can't categorize it, return nil (will need manual classification)
        return nil
    }
    
    // MARK: - Phoneme Parsing
    
    private func parsePhonemes(_ phonetic: String) -> [String] {
        // Remove slashes and split into phonemes
        let cleaned = phonetic
            .replacingOccurrences(of: "/", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Split by spaces (IPA notation typically separates phonemes with spaces)
        return cleaned.split(separator: " ").map { String($0) }
    }
    
    // MARK: - Alignment
    
    private func alignPhonemes(expected: [String], produced: [String]) -> [(String?, String?)] {
        // Simple alignment - in production, use dynamic programming (Needleman-Wunsch)
        var result: [(String?, String?)] = []
        
        let maxLen = max(expected.count, produced.count)
        
        for i in 0..<maxLen {
            let exp: String? = i < expected.count ? expected[i] : nil
            let prod: String? = i < produced.count ? produced[i] : nil
            result.append((exp, prod))
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func isWordInitial(phoneme: String, in phonemes: [String]) -> Bool {
        phonemes.first == phoneme
    }
    
    private func isWordFinal(phoneme: String, in phonemes: [String]) -> Bool {
        phonemes.last == phoneme
    }
    
    private func sameMannerOfArticulation(_ a: String, _ b: String) -> Bool {
        // Check if both are same type (both stops, both fricatives, etc.)
        if stops.contains(a) && stops.contains(b) { return true }
        if fricatives.contains(a) && fricatives.contains(b) { return true }
        if nasals.contains(a) && nasals.contains(b) { return true }
        if affricates.contains(a) && affricates.contains(b) { return true }
        return false
    }
    
    // MARK: - Pattern Descriptions
    
    /// Get developmental norms for when an error pattern should be eliminated
    func developmentalNorm(for pattern: ErrorPattern) -> String? {
        switch pattern {
        case .gliding:
            return "Typically eliminated by age 5-6"
        case .frontalLisp:
            return "Should be addressed if persisting past age 4-5"
        case .lateralLisp:
            return "Not developmentally typical; intervention recommended"
        case .stopping:
            return "Typically eliminated by age 3-5 depending on sound"
        case .fronting:
            return "Typically eliminated by age 3.5-4"
        case .backing:
            return "Not developmentally typical; intervention recommended"
        case .clusterReduction:
            return "Typically eliminated by age 4-5"
        case .finalConsonantDeletion:
            return "Typically eliminated by age 3-3.5"
        case .initialConsonantDeletion:
            return "Not developmentally typical; intervention recommended"
        case .deaffrication:
            return "Typically eliminated by age 4"
        case .affrication:
            return "Not developmentally typical at any age"
        case .voicing, .devoicing:
            return "Typically resolved by age 4"
        case .vowelSubstitution:
            return "Varies by specific vowel"
        case .nasalization, .denasalization:
            return "May indicate structural issues; evaluation recommended"
        case .custom:
            return nil
        }
    }
    
    /// Get suggested intervention approaches for an error pattern
    func interventionSuggestions(for pattern: ErrorPattern) -> [String] {
        switch pattern {
        case .gliding:
            return [
                "Minimal pairs therapy (/w/ vs /r/, /w/ vs /l/)",
                "Phonetic placement techniques",
                "Auditory discrimination training"
            ]
        case .frontalLisp:
            return [
                "Tongue placement training",
                "Visual feedback with mirror",
                "Tactile cues for alveolar ridge contact"
            ]
        case .stopping:
            return [
                "Minimal pairs therapy",
                "Emphasize continuant nature of fricatives",
                "Airflow awareness activities"
            ]
        case .fronting:
            return [
                "Minimal pairs therapy (/t/ vs /k/, /d/ vs /g/)",
                "Back of tongue awareness",
                "Tactile cues for velar contact"
            ]
        default:
            return ["Consult clinical resources for pattern-specific intervention"]
        }
    }
}
