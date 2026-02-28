import Foundation

// MARK: - Word Status
enum WordStatus: String, Codable {
    case clean
    case flagged
    case confirmed
    case dismissed
}

// MARK: - Transcribed Word
struct TranscribedWord: Identifiable, Codable {
    let id: UUID
    var text: String
    var confidence: Float
    var startTime: TimeInterval
    var endTime: TimeInterval
    var status: WordStatus
    var autoPhonetic: String?
    var expectedPhonetic: String?
    var suggestedErrors: [SuggestedError]
    var manualPhonetic: String?
    
    init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        startTime: TimeInterval,
        endTime: TimeInterval,
        status: WordStatus = .clean,
        autoPhonetic: String? = nil,
        expectedPhonetic: String? = nil,
        suggestedErrors: [SuggestedError] = [],
        manualPhonetic: String? = nil
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.autoPhonetic = autoPhonetic
        self.expectedPhonetic = expectedPhonetic
        self.suggestedErrors = suggestedErrors
        self.manualPhonetic = manualPhonetic
    }
    
    var displayPhonetic: String? {
        // If flagged but not yet confirmed, return nil to indicate manual input needed
        // Once confirmed, return the manual or auto phonetic
        switch status {
        case .flagged:
            return nil // Will show placeholder symbol in UI
        case .confirmed:
            return manualPhonetic ?? autoPhonetic
        case .clean, .dismissed:
            return manualPhonetic ?? autoPhonetic
        }
    }
    
    var requiresManualInput: Bool {
        status == .flagged
    }
    
    var duration: TimeInterval {
        endTime - startTime
    }
}

// MARK: - Suggested Error
struct SuggestedError: Identifiable, Codable {
    let id: UUID
    let target: String
    let produced: String
    let pattern: ErrorPattern
    
    init(id: UUID = UUID(), target: String, produced: String, pattern: ErrorPattern) {
        self.id = id
        self.target = target
        self.produced = produced
        self.pattern = pattern
    }
}

// MARK: - Confirmed Error
struct ConfirmedError: Identifiable, Codable {
    let id: UUID
    let wordId: UUID
    let word: String
    let timestamp: TimeInterval
    let target: String
    let produced: String
    let pattern: ErrorPattern
    let phonetic: String
    let expected: String
    let isCustom: Bool
    let confirmedAt: Date
    
    init(
        id: UUID = UUID(),
        wordId: UUID,
        word: String,
        timestamp: TimeInterval,
        target: String,
        produced: String,
        pattern: ErrorPattern,
        phonetic: String,
        expected: String,
        isCustom: Bool = false,
        confirmedAt: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.word = word
        self.timestamp = timestamp
        self.target = target
        self.produced = produced
        self.pattern = pattern
        self.phonetic = phonetic
        self.expected = expected
        self.isCustom = isCustom
        self.confirmedAt = confirmedAt
    }
}

// MARK: - Error Pattern
enum ErrorPattern: String, Codable, CaseIterable {
    case gliding = "Gliding"
    case frontalLisp = "Frontal Lisp"
    case lateralLisp = "Lateral Lisp"
    case stopping = "Stopping"
    case fronting = "Fronting"
    case backing = "Backing"
    case clusterReduction = "Cluster Reduction"
    case finalConsonantDeletion = "Final Consonant Deletion"
    case initialConsonantDeletion = "Initial Consonant Deletion"
    case vowelSubstitution = "Vowel Substitution"
    case deaffrication = "Deaffrication"
    case affrication = "Affrication"
    case voicing = "Voicing"
    case devoicing = "Devoicing"
    case nasalization = "Nasalization"
    case denasalization = "Denasalization"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .gliding:
            return "Substitution of a glide for a liquid (/w/ or /j/ for /r/ or /l/)"
        case .frontalLisp:
            return "Tongue protrudes between teeth during /s/ and /z/ production"
        case .lateralLisp:
            return "Air escapes over the sides of the tongue during /s/ and /z/"
        case .stopping:
            return "Substitution of a stop consonant for a fricative or affricate"
        case .fronting:
            return "Substitution of alveolar consonants for velar consonants"
        case .backing:
            return "Substitution of velar consonants for alveolar consonants"
        case .clusterReduction:
            return "Deletion of one or more consonants in a cluster"
        case .finalConsonantDeletion:
            return "Omission of the final consonant in words"
        case .initialConsonantDeletion:
            return "Omission of the initial consonant in words"
        case .vowelSubstitution:
            return "Replacement of one vowel sound with another"
        case .deaffrication:
            return "Substitution of a fricative for an affricate"
        case .affrication:
            return "Substitution of an affricate for a fricative"
        case .voicing:
            return "Substitution of a voiced consonant for a voiceless consonant"
        case .devoicing:
            return "Substitution of a voiceless consonant for a voiced consonant"
        case .nasalization:
            return "Addition of nasal quality to non-nasal sounds"
        case .denasalization:
            return "Substitution of a non-nasal for a nasal consonant"
        case .custom:
            return "Custom error pattern identified by clinician"
        }
    }
}

// MARK: - Session
struct Session: Identifiable, Codable {
    let id: UUID
    var studentName: String
    var date: Date
    var duration: TimeInterval
    var transcription: [TranscribedWord]
    var confirmedErrors: [ConfirmedError]
    var clinicalNotes: String
    var audioFileURL: URL?
    
    init(
        id: UUID = UUID(),
        studentName: String = "",
        date: Date = Date(),
        duration: TimeInterval = 0,
        transcription: [TranscribedWord] = [],
        confirmedErrors: [ConfirmedError] = [],
        clinicalNotes: String = "",
        audioFileURL: URL? = nil
    ) {
        self.id = id
        self.studentName = studentName
        self.date = date
        self.duration = duration
        self.transcription = transcription
        self.confirmedErrors = confirmedErrors
        self.clinicalNotes = clinicalNotes
        self.audioFileURL = audioFileURL
    }
    
    var errorPatternCounts: [ErrorPattern: Int] {
        var counts: [ErrorPattern: Int] = [:]
        for error in confirmedErrors {
            counts[error.pattern, default: 0] += 1
        }
        return counts
    }
    
    var flaggedWordsCount: Int {
        transcription.filter { $0.status == .flagged }.count
    }
    
    var totalWords: Int {
        transcription.count
    }
}

// MARK: - Recording State
enum RecordingState {
    case idle
    case recording
    case processing
    case complete
    case error(String)
}

// MARK: - IPA Symbols
struct IPAKeyboard {
    static let consonants: [[String]] = [
        ["p", "b", "t", "d", "k", "ɡ", "ʔ"],
        ["m", "n", "ŋ", "ɹ", "l", "w", "j"],
        ["f", "v", "θ", "ð", "s", "z", "ʃ"],
        ["ʒ", "h", "tʃ", "dʒ", "ɾ", "ʍ", "x"]
    ]
    
    static let vowels: [[String]] = [
        ["i", "ɪ", "e", "ɛ", "æ", "ə", "ʌ"],
        ["ɑ", "ɔ", "o", "ʊ", "u", "aɪ", "aʊ"],
        ["ɔɪ", "eɪ", "oʊ", "ɝ", "ɚ", "ɐ", "ɒ"]
    ]
    
    static let diacritics: [String] = ["ː", "ˈ", "ˌ", "̃", "̥", "̬", "ʰ", "ʷ"]
    
    static var allSymbols: [[String]] {
        consonants + vowels + [diacritics]
    }
}

// MARK: - Confidence Threshold
struct ConfidenceThreshold {
    static let low: Float = 0.5
    static let medium: Float = 0.7
    static let high: Float = 0.85
    
    static func category(for confidence: Float) -> ThresholdCategory {
        if confidence >= high {
            return .high
        } else if confidence >= medium {
            return .medium
        } else {
            return .low
        }
    }
    
    enum ThresholdCategory {
        case low, medium, high
        
        var color: String {
            switch self {
            case .low: return "red"
            case .medium: return "orange"
            case .high: return "green"
            }
        }
    }
}
