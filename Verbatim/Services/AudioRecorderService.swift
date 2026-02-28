import Foundation
import AVFoundation

/// Service responsible for recording audio
@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevels: [Float] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Public Properties
    var currentRecordingURL: URL? {
        recordingURL
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recording Controls
    
    /// Start recording audio
    func startRecording() throws -> URL {
        // Create unique filename
        let filename = "recording_\(Date().timeIntervalSince1970).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(filename)
        
        // Recording settings optimized for speech
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            recordingURL = audioURL
            isRecording = true
            startTime = Date()
            recordingDuration = 0
            audioLevels = []
            
            startTimers()
            
            return audioURL
        } catch {
            throw RecordingError.failedToStart(error.localizedDescription)
        }
    }
    
    /// Stop recording
    func stopRecording() -> URL? {
        stopTimers()
        
        audioRecorder?.stop()
        isRecording = false
        
        return recordingURL
    }
    
    /// Pause recording
    func pauseRecording() {
        audioRecorder?.pause()
    }
    
    /// Resume recording
    func resumeRecording() {
        audioRecorder?.record()
    }
    
    // MARK: - Timer Management
    
    private func startTimers() {
        // Update audio levels at 60fps for smooth visualization
        levelTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevels()
            }
        }
        
        // Update duration every 100ms
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }
    
    private func stopTimers() {
        levelTimer?.invalidate()
        levelTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        
        // Normalize level from dB (-160 to 0) to 0-1 range
        let normalizedLevel = max(0, (level + 60) / 60)
        
        DispatchQueue.main.async {
            self.audioLevels.append(normalizedLevel)
            
            // Keep last 100 samples for visualization
            if self.audioLevels.count > 100 {
                self.audioLevels.removeFirst()
            }
        }
    }
    
    private func updateDuration() {
        guard let start = startTime else { return }
        
        DispatchQueue.main.async {
            self.recordingDuration = Date().timeIntervalSince(start)
        }
    }
    
    // MARK: - Audio Segment Extraction
    
    /// Extract a segment of audio for detailed analysis
    func extractAudioSegment(from url: URL, startTime: TimeInterval, endTime: TimeInterval) async throws -> URL {
        let asset = AVURLAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw RecordingError.exportFailed("Failed to create export session")
        }
        
        // Create output URL for segment
        let filename = "segment_\(startTime)_\(endTime).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent(filename)
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
        exportSession.timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw RecordingError.exportFailed(error.localizedDescription)
        }
        
        return outputURL
    }
    
    // MARK: - Cleanup
    
    /// Delete a recording file
    func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Delete all temporary recordings
    func cleanupTemporaryRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "m4a" {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            errorMessage = "Failed to cleanup recordings: \(error.localizedDescription)"
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.errorMessage = "Recording finished unsuccessfully"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.errorMessage = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - Errors
enum RecordingError: LocalizedError {
    case failedToStart(String)
    case exportFailed(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedToStart(let reason):
            return "Failed to start recording: \(reason)"
        case .exportFailed(let reason):
            return "Failed to export audio segment: \(reason)"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}
