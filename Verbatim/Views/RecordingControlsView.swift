import SwiftUI

struct RecordingControlsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Record button
                recordButton
                
                // Waveform and duration
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(sessionManager.audioService.isRecording ? "Recording..." : "Ready to record")
                            .font(.subheadline)
                            .foregroundColor(sessionManager.audioService.isRecording ? .red : .secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(sessionManager.audioService.recordingDuration))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    // Waveform visualization
                    waveformView
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .alert("Recording Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(
                        sessionManager.audioService.isRecording
                            ? AnyShapeStyle(Color.red)
                            : AnyShapeStyle(LinearGradient(
                                colors: [.blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: sessionManager.audioService.isRecording ? .red.opacity(0.4) : .blue.opacity(0.4), radius: 8)
                
                if sessionManager.audioService.isRecording {
                    // Stop icon
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                } else {
                    // Microphone icon
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(sessionManager.audioService.isRecording ? 1.05 : 1.0)
        .animation(
            sessionManager.audioService.isRecording
                ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                : .default,
            value: sessionManager.audioService.isRecording
        )
    }
    
    // MARK: - Waveform View
    
    private var waveformView: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<Int(geometry.size.width / 4), id: \.self) { index in
                    waveformBar(at: index)
                }
            }
        }
        .frame(height: 32)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func waveformBar(at index: Int) -> some View {
        let levels = sessionManager.audioService.audioLevels
        let level: Float
        
        if sessionManager.audioService.isRecording && !levels.isEmpty {
            // Use actual audio levels when recording
            let levelIndex = min(index, levels.count - 1)
            level = levels.isEmpty ? 0.1 : levels[max(0, levelIndex)]
        } else {
            // Show static bars when not recording
            level = 0.15
        }
        
        return RoundedRectangle(cornerRadius: 1)
            .fill(sessionManager.audioService.isRecording ? Color.blue : Color(.systemGray4))
            .frame(width: 2, height: CGFloat(max(4, level * 28)))
            .animation(.easeOut(duration: 0.1), value: level)
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        Task {
            if sessionManager.audioService.isRecording {
                sessionManager.stopRecording()
            } else {
                do {
                    try await sessionManager.startRecording()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let centiseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

// MARK: - Audio Level Indicator

struct AudioLevelIndicator: View {
    var level: Float
    var isActive: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: 16)
                    .opacity(shouldShow(index) ? 1.0 : 0.3)
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        if index < 6 {
            return .green
        } else if index < 8 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func shouldShow(_ index: Int) -> Bool {
        guard isActive else { return false }
        let threshold = Float(index) / 10.0
        return level >= threshold
    }
}

#Preview {
    RecordingControlsView()
        .environmentObject(SessionManager())
        .padding()
}
