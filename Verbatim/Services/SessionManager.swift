import Foundation
import SwiftUI

/// Manages session state and persistence
@MainActor
class SessionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSession: Session
    @Published var savedSessions: [Session] = []
    @Published var selectedWord: TranscribedWord?
    @Published var viewMode: ViewMode = .transcription
    
    // MARK: - Services
    let speechService: SpeechRecognitionService
    let audioService: AudioRecorderService
    
    // MARK: - Types
    enum ViewMode {
        case transcription
        case analysis
    }
    
    // MARK: - Initialization
    init() {
        self.currentSession = Session()
        self.speechService = SpeechRecognitionService()
        self.audioService = AudioRecorderService()
        loadSavedSessions()
    }
    
    // MARK: - Session Management
    
    /// Start a new session
    func startNewSession(studentName: String = "") {
        currentSession = Session(studentName: studentName)
        selectedWord = nil
    }
    
    /// Save the current session
    func saveCurrentSession() {
        // Update session with latest transcription
        currentSession.transcription = speechService.transcribedWords
        currentSession.duration = audioService.recordingDuration
        
        // Add to saved sessions
        if let index = savedSessions.firstIndex(where: { $0.id == currentSession.id }) {
            savedSessions[index] = currentSession
        } else {
            savedSessions.append(currentSession)
        }
        
        persistSessions()
    }
    
    /// Load a saved session
    func loadSession(_ session: Session) {
        currentSession = session
        speechService.transcribedWords = session.transcription
    }
    
    /// Delete a session
    func deleteSession(_ session: Session) {
        savedSessions.removeAll { $0.id == session.id }
        
        // Delete associated audio file
        if let audioURL = session.audioFileURL {
            audioService.deleteRecording(at: audioURL)
        }
        
        persistSessions()
    }
    
    // MARK: - Word Management
    
    /// Select a word for detail view
    func selectWord(_ word: TranscribedWord) {
        if word.status != .clean {
            selectedWord = word
        }
    }
    
    /// Dismiss word selection
    func dismissWordSelection() {
        selectedWord = nil
    }
    
    /// Confirm an error for a word
    func confirmError(for word: TranscribedWord, error: SuggestedError, phonetic: String? = nil) {
        let confirmedError = ConfirmedError(
            wordId: word.id,
            word: word.text,
            timestamp: word.startTime,
            target: error.target,
            produced: error.produced,
            pattern: error.pattern,
            phonetic: phonetic ?? word.autoPhonetic ?? "",
            expected: word.expectedPhonetic ?? ""
        )
        
        currentSession.confirmedErrors.append(confirmedError)
        
        // Update word status
        updateWordStatus(word.id, to: .confirmed)
        
        selectedWord = nil
    }
    
    /// Add a custom error
    func addCustomError(for word: TranscribedWord, phonetic: String, pattern: ErrorPattern = .custom) {
        let confirmedError = ConfirmedError(
            wordId: word.id,
            word: word.text,
            timestamp: word.startTime,
            target: "?",
            produced: "?",
            pattern: pattern,
            phonetic: phonetic,
            expected: word.expectedPhonetic ?? "",
            isCustom: true
        )
        
        currentSession.confirmedErrors.append(confirmedError)
        
        // Update word status and phonetic
        if let index = currentSession.transcription.firstIndex(where: { $0.id == word.id }) {
            currentSession.transcription[index].status = .confirmed
            currentSession.transcription[index].manualPhonetic = phonetic
            speechService.transcribedWords = currentSession.transcription
        }
        
        selectedWord = nil
    }
    
    /// Dismiss a flag (mark as not an error)
    func dismissFlag(for word: TranscribedWord) {
        updateWordStatus(word.id, to: .dismissed)
        selectedWord = nil
    }
    
    /// Remove a confirmed error
    func removeError(_ error: ConfirmedError) {
        currentSession.confirmedErrors.removeAll { $0.id == error.id }
        
        // Reset word status to flagged
        updateWordStatus(error.wordId, to: .flagged)
    }
    
    // MARK: - Private Methods
    
    private func updateWordStatus(_ wordId: UUID, to status: WordStatus) {
        if let index = currentSession.transcription.firstIndex(where: { $0.id == wordId }) {
            currentSession.transcription[index].status = status
            speechService.transcribedWords = currentSession.transcription
        }
    }
    
    // MARK: - Persistence
    
    private var sessionsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("sessions.json")
    }
    
    private func persistSessions() {
        do {
            let data = try JSONEncoder().encode(savedSessions)
            try data.write(to: sessionsFileURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    private func loadSavedSessions() {
        do {
            let data = try Data(contentsOf: sessionsFileURL)
            savedSessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            // No saved sessions or failed to load
            savedSessions = []
        }
    }
    
    // MARK: - Recording Integration
    
    /// Start recording and transcription
    func startRecording() async throws {
        let url = try audioService.startRecording()
        currentSession.audioFileURL = url
        try speechService.startLiveTranscription()
    }
    
    /// Stop recording and transcription
    func stopRecording() {
        speechService.stopLiveTranscription()
        _ = audioService.stopRecording()
        
        // Copy transcription to session
        currentSession.transcription = speechService.transcribedWords
        currentSession.duration = audioService.recordingDuration
    }
    
    // MARK: - Clinical Notes
    
    func updateClinicalNotes(_ notes: String) {
        currentSession.clinicalNotes = notes
    }
    
    // MARK: - Statistics
    
    var errorPatternCounts: [ErrorPattern: Int] {
        currentSession.errorPatternCounts
    }
    
    var flaggedWordsCount: Int {
        currentSession.flaggedWordsCount
    }
    
    var confirmedErrorsCount: Int {
        currentSession.confirmedErrors.count
    }
}
