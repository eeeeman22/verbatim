import Foundation
import SwiftUI
import Combine

/// ViewModel for the transcription view
@MainActor
class TranscriptionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recordingState: RecordingState = .idle
    @Published var customPhonetic: String = ""
    @Published var showIPAKeyboard: Bool = false
    @Published var confidenceThreshold: Float = 0.7
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Services
    private let sessionManager: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var transcribedWords: [TranscribedWord] {
        sessionManager.speechService.transcribedWords
    }
    
    var selectedWord: TranscribedWord? {
        sessionManager.selectedWord
    }
    
    var isRecording: Bool {
        sessionManager.audioService.isRecording
    }
    
    var recordingDuration: TimeInterval {
        sessionManager.audioService.recordingDuration
    }
    
    var audioLevels: [Float] {
        sessionManager.audioService.audioLevels
    }
    
    var flaggedWordsCount: Int {
        transcribedWords.filter { $0.status == .flagged }.count
    }
    
    var confirmedErrorsCount: Int {
        sessionManager.currentSession.confirmedErrors.count
    }
    
    // MARK: - Initialization
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        
        // Update confidence threshold in speech service
        sessionManager.speechService.confidenceThreshold = confidenceThreshold
        
        // Observe confidence threshold changes
        $confidenceThreshold
            .sink { [weak self] threshold in
                self?.sessionManager.speechService.confidenceThreshold = threshold
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Recording Actions
    
    func toggleRecording() {
        Task {
            if isRecording {
                stopRecording()
            } else {
                await startRecording()
            }
        }
    }
    
    private func startRecording() async {
        do {
            recordingState = .recording
            try await sessionManager.startRecording()
        } catch {
            recordingState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func stopRecording() {
        sessionManager.stopRecording()
        recordingState = .complete
    }
    
    // MARK: - Word Selection
    
    func selectWord(_ word: TranscribedWord) {
        sessionManager.selectWord(word)
        customPhonetic = word.displayPhonetic ?? ""
        showIPAKeyboard = false
    }
    
    func dismissWordSelection() {
        sessionManager.dismissWordSelection()
        customPhonetic = ""
        showIPAKeyboard = false
    }
    
    // MARK: - Error Confirmation
    
    func confirmError(_ error: SuggestedError) {
        guard let word = selectedWord else { return }
        sessionManager.confirmError(for: word, error: error, phonetic: customPhonetic.isEmpty ? nil : customPhonetic)
    }
    
    func saveCustomTranscription() {
        guard let word = selectedWord, !customPhonetic.isEmpty else { return }
        sessionManager.addCustomError(for: word, phonetic: customPhonetic)
    }
    
    func dismissFlag() {
        guard let word = selectedWord else { return }
        sessionManager.dismissFlag(for: word)
    }
    
    // MARK: - IPA Keyboard
    
    func insertIPA(_ symbol: String) {
        customPhonetic += symbol
    }
    
    func deleteLastIPA() {
        if !customPhonetic.isEmpty {
            customPhonetic.removeLast()
        }
    }
    
    func clearIPA() {
        customPhonetic = ""
    }
    
    // MARK: - Formatting Helpers
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let centiseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        } else {
            return String(format: "00:%02d.%02d", seconds, centiseconds)
        }
    }
    
    func confidenceColor(for confidence: Float) -> Color {
        switch ConfidenceThreshold.category(for: confidence) {
        case .high:
            return .green
        case .medium:
            return .orange
        case .low:
            return .red
        }
    }
    
    func wordBackgroundColor(for word: TranscribedWord) -> Color {
        switch word.status {
        case .clean:
            return .clear
        case .flagged:
            return Color.orange.opacity(0.2)
        case .confirmed:
            return Color.red.opacity(0.2)
        case .dismissed:
            return Color.gray.opacity(0.1)
        }
    }
    
    func wordBorderColor(for word: TranscribedWord) -> Color {
        switch word.status {
        case .clean:
            return .clear
        case .flagged:
            return .orange
        case .confirmed:
            return .red
        case .dismissed:
            return .gray
        }
    }
}
