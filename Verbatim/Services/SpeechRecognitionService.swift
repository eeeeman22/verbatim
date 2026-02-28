import Foundation
import Speech
import AVFoundation

/// Service responsible for speech recognition using Apple's Speech framework
/// Provides word-level transcription with confidence scores
@MainActor
class SpeechRecognitionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isProcessing = false
    @Published var transcribedWords: [TranscribedWord] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    /// Confidence threshold below which words are flagged for review
    var confidenceThreshold: Float = 0.7
    
    // MARK: - Initialization
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition not authorized"
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Live Transcription
    
    /// Start live transcription from microphone input
    func startLiveTranscription() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        
        // Request detailed results for better confidence scores
        if #available(iOS 16, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start recognition task
        isProcessing = true
        transcribedWords = []
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.processTranscriptionResult(result)
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isProcessing = false
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    /// Stop live transcription
    func stopLiveTranscription() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isProcessing = false
    }
    
    // MARK: - File-based Transcription
    
    /// Transcribe an audio file
    func transcribeAudioFile(url: URL) async throws -> [TranscribedWord] {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let words = self?.convertToTranscribedWords(from: result.bestTranscription) ?? []
                continuation.resume(returning: words)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processTranscriptionResult(_ result: SFSpeechRecognitionResult) {
        let words = convertToTranscribedWords(from: result.bestTranscription)
        
        DispatchQueue.main.async {
            self.transcribedWords = words
        }
    }
    
    private func convertToTranscribedWords(from transcription: SFTranscription) -> [TranscribedWord] {
        // Try to use segments with confidence, but fall back to words if needed
        var words: [TranscribedWord] = []
        
        // Check if we have segments with meaningful confidence scores
        let hasConfidence = transcription.segments.contains { $0.confidence > 0 }
        
        if hasConfidence {
            // Use segments as normal
            words = transcription.segments.map { segment in
                createTranscribedWord(
                    text: segment.substring,
                    confidence: segment.confidence,
                    startTime: segment.timestamp,
                    duration: segment.duration
                )
            }
        } else {
            // Fall back to using alternativeSubstrings for confidence estimation
            // or use a heuristic based on word characteristics
            for segment in transcription.segments {
                // Estimate confidence based on alternatives if available
                let estimatedConfidence = estimateConfidence(for: segment, in: transcription)
                
                words.append(createTranscribedWord(
                    text: segment.substring,
                    confidence: estimatedConfidence,
                    startTime: segment.timestamp,
                    duration: segment.duration
                ))
            }
        }
        
        return words
    }
    
    /// Estimates confidence when segment.confidence is not available
    private func estimateConfidence(for segment: SFTranscriptionSegment, in transcription: SFTranscription) -> Float {
        // If there are alternative transcriptions, we can estimate lower confidence
        // For now, use a heuristic based on word length and common words
        let text = segment.substring.lowercased()
        
        // Common words tend to be recognized better
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        if commonWords.contains(text) {
            return 0.95 // High confidence for common words
        }
        
        // Longer words might have more uncertainty
        if text.count > 8 {
            return 0.65
        } else if text.count > 5 {
            return 0.80
        }
        
        return 0.85 // Default moderate-high confidence
    }
    
    private func createTranscribedWord(text: String, confidence: Float, startTime: TimeInterval, duration: TimeInterval) -> TranscribedWord {
        let status: WordStatus = confidence < confidenceThreshold ? .flagged : .clean
        
        var word = TranscribedWord(
            text: text,
            confidence: confidence,
            startTime: startTime,
            endTime: startTime + duration,
            status: status
        )
        
        // Always look up expected pronunciation (needed for display of low-confidence clean words)
        word.expectedPhonetic = PronunciationDictionary.shared.lookup(text)
        
        // For flagged words, generate simulated phonetic and error analysis
        if status == .flagged {
            // For demo purposes, generate a simulated "detected" phonetic
            // In production, this would come from a phoneme recognition model
            word.autoPhonetic = generateSimulatedPhonetic(for: text, confidence: confidence)
            
            // Analyze for potential error patterns
            if let expected = word.expectedPhonetic, let produced = word.autoPhonetic {
                word.suggestedErrors = ErrorPatternAnalyzer.shared.analyzeErrors(
                    expected: expected,
                    produced: produced
                )
            }
        }
        
        return word
    }
    
    /// Simulates phonetic output for demo purposes
    /// In production, this would be replaced with actual phoneme model output
    private func generateSimulatedPhonetic(for word: String, confidence: Float) -> String? {
        guard let expected = PronunciationDictionary.shared.lookup(word) else {
            return nil
        }
        
        // Simulate common error patterns based on confidence
        // Lower confidence = more likely to have errors
        if confidence < 0.4 {
            // Apply simulated error transformations
            return applySimulatedErrors(to: expected)
        }
        
        return expected
    }
    
    private func applySimulatedErrors(to phonetic: String) -> String {
        var result = phonetic
        
        // Simulate common substitutions
        let substitutions: [(String, String)] = [
            ("ɹ", "w"),  // Gliding
            ("l", "w"),  // Gliding
            ("s", "θ"),  // Frontal lisp
            ("z", "ð"),  // Frontal lisp
            ("k", "t"),  // Fronting
            ("ɡ", "d"),  // Fronting
        ]
        
        // Randomly apply one substitution for demo
        if let (target, replacement) = substitutions.randomElement() {
            result = result.replacingOccurrences(of: target, with: replacement)
        }
        
        return result
    }
}

// MARK: - Errors
enum SpeechRecognitionError: LocalizedError {
    case recognizerNotAvailable
    case requestCreationFailed
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .notAuthorized:
            return "Speech recognition not authorized"
        }
    }
}
