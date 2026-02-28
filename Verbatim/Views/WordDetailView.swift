import AVFoundation
import SwiftUI

struct WordDetailView: View {
    @EnvironmentObject var sessionManager: SessionManager
    let word: TranscribedWord

    @State private var customPhonetic: String = ""
    @State private var showIPAKeyboard: Bool = false
    @State private var isPlayingAudio: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Word info card
                wordInfoCard

                // Audio playback
                audioPlaybackButton

                // Suggested errors
                if !word.suggestedErrors.isEmpty {
                    suggestedErrorsSection
                }

                // Manual transcription
                manualTranscriptionSection

                // Dismiss button
                dismissButton
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear {
            customPhonetic = word.displayPhonetic ?? ""
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Word Detail")
                .font(.headline)

            Spacer()

            Button(action: { sessionManager.dismissWordSelection() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
    }

    // MARK: - Word Info Card

    private var wordInfoCard: some View {
        VStack(spacing: 16) {
            // Word display
            Text("\"\(word.text)\"")
                .font(.system(size: 32, weight: .medium, design: .serif))
                .foregroundColor(.primary)

            // Phonetic comparison
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(word.expectedPhonetic ?? "—")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(word.autoPhonetic ?? "—")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                }
            }

            // Confidence bar
            VStack(alignment: .leading, spacing: 4) {
                Text("ASR Confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(confidenceColor)
                                .frame(
                                    width: geometry.size.width
                                        * CGFloat(word.confidence)
                                )
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(word.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var confidenceColor: Color {
        if word.confidence >= 0.7 {
            return .green
        } else if word.confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Audio Playback

    private var audioPlaybackButton: some View {
        Button(action: playAudioSegment) {
            HStack {
                Image(systemName: isPlayingAudio ? "stop.fill" : "play.fill")
                Text("Play Segment (\(String(format: "%.2fs", word.duration)))")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func playAudioSegment() {
        // In production, this would extract and play the audio segment
        // For now, just toggle the state briefly
        isPlayingAudio = true
        DispatchQueue.main.asyncAfter(deadline: .now() + word.duration) {
            isPlayingAudio = false
        }
    }

    // MARK: - Suggested Errors

    private var suggestedErrorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Errors")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(word.suggestedErrors) { error in
                suggestedErrorCard(error)
            }
        }
    }

    private func suggestedErrorCard(_ error: SuggestedError) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Phoneme comparison
                HStack(spacing: 8) {
                    Text("/\(error.target)/")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.green)

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    Text("/\(error.produced)/")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.red)
                }

                Spacer()

                // Pattern badge
                Text(error.pattern.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }

            // Confirm button
            Button(action: { confirmError(error) }) {
                Text("Confirm This Error")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private func confirmError(_ error: SuggestedError) {
        sessionManager.confirmError(
            for: word,
            error: error,
            phonetic: customPhonetic.isEmpty ? nil : customPhonetic
        )
    }

    // MARK: - Manual Transcription

    private var manualTranscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Transcription")
                .font(.subheadline)
                .fontWeight(.medium)

            // Text field
            HStack {
                TextField("/enter IPA/", text: $customPhonetic)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .onTapGesture {
                        showIPAKeyboard = true
                    }

                Button(action: { showIPAKeyboard.toggle() }) {
                    Image(systemName: "keyboard")
                        .foregroundColor(.blue)
                }
            }

            // IPA Keyboard
            if showIPAKeyboard {
                IPAKeyboardView(
                    text: $customPhonetic,
                    onDismiss: { showIPAKeyboard = false }
                )
            }

            // Save button
            Button(action: saveCustomTranscription) {
                Text("Save Custom Transcription")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        customPhonetic.isEmpty ? Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(customPhonetic.isEmpty)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func saveCustomTranscription() {
        sessionManager.addCustomError(for: word, phonetic: customPhonetic)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button(action: { sessionManager.dismissFlag(for: word) }) {
            Text("Dismiss Flag (No Error)")
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

#Preview {
    let word = TranscribedWord(
        text: "rabbit",
        confidence: 0.42,
        startTime: 0.25,
        endTime: 0.8,
        status: .flagged,
        autoPhonetic: "/w æ b ɪ t/",
        expectedPhonetic: "/ɹ æ b ɪ t/",
        suggestedErrors: [
            SuggestedError(target: "ɹ", produced: "w", pattern: .gliding)
        ]
    )

    return WordDetailView(word: word)
        .environmentObject(SessionManager())
}
