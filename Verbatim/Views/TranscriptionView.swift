import SwiftUI

struct TranscriptionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel: TranscriptionViewModel
    
    init() {
        // We'll initialize the viewModel properly in onAppear
        _viewModel = StateObject(wrappedValue: TranscriptionViewModel(sessionManager: SessionManager()))
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // iPad / Large screen layout
                HStack(spacing: 0) {
                    // Main transcription area
                    mainContent
                        .frame(width: geometry.size.width * 0.65)
                    
                    Divider()
                    
                    // Word detail panel
                    wordDetailPanel
                        .frame(width: geometry.size.width * 0.35)
                }
            } else {
                // iPhone layout
                ZStack {
                    mainContent
                    
                    // Slide-over detail panel
                    if sessionManager.selectedWord != nil {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                sessionManager.dismissWordSelection()
                            }
                        
                        VStack {
                            Spacer()
                            wordDetailPanel
                                .frame(maxHeight: geometry.size.height * 0.7)
                                .background(Color(.systemBackground))
                                .cornerRadius(20, corners: [.topLeft, .topRight])
                                .shadow(radius: 10)
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                .animation(.spring(response: 0.3), value: sessionManager.selectedWord != nil)
            }
        }
        .onAppear {
            // Reinitialize viewModel with correct sessionManager
            // This is a workaround since we can't access EnvironmentObject in init
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Recording controls
            RecordingControlsView()
            
            // Transcription display
            transcriptionDisplay
            
            // Disclaimer
            disclaimerBanner
        }
        .padding()
    }
    
    // MARK: - Transcription Display
    
    private var transcriptionDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                
                Spacer()
                
                legendView
            }
            
            ScrollView {
                if sessionManager.speechService.transcribedWords.isEmpty {
                    emptyStateView
                } else {
                    flowLayoutText
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            HStack {
                Text("Tap any word to review or edit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let flaggedCount = sessionManager.speechService.transcribedWords.filter { $0.status == .flagged }.count
                if flaggedCount > 0 {
                    Text("\(flaggedCount) items need review")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No transcription yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the record button to start")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var flowLayoutText: some View {
        FlowLayout(spacing: 4) {
            ForEach(sessionManager.speechService.transcribedWords) { word in
                wordView(for: word)
            }
        }
        .padding()
    }
    
    private func wordView(for word: TranscribedWord) -> some View {
        Group {
            // Determine what to display based on word status and confidence
            switch word.status {
            case .flagged:
                // Show placeholder symbol when flagged but not yet confirmed
                Text("⋯")
                    .font(.system(.title3, weight: .bold))
                    .foregroundColor(.orange)
                
            case .confirmed:
                // Show phonetic transcription for confirmed words
                if let phonetic = word.displayPhonetic {
                    Text(phonetic)
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text(word.text)
                        .font(.system(.title3, design: .serif))
                }
                
            case .clean, .dismissed:
                // For clean/dismissed words, display based on confidence level
                if word.confidence >= 0.7 {
                    // Medium to high confidence (>= 0.7): show "maybe" prefix
                    Text("maybe \(word.text)")
                        .font(.system(.title3, design: .serif))
                } else if word.confidence > 0 {
                    // Low confidence (< 0.7): don't show word text, only phonetic if available
                    if let phonetic = word.expectedPhonetic {
                        Text(phonetic)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        // No phonetic available for low confidence word
                        Text("?")
                            .font(.system(.title3, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Confidence is 0 (not available) - show word text normally
                    Text(word.text)
                        .font(.system(.title3, design: .serif))
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(wordBackgroundColor(for: word))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(wordBorderColor(for: word), lineWidth: word.status == .clean ? 0 : 2)
        )
        .cornerRadius(4)
        .onTapGesture {
            // Only allow tapping flagged or confirmed words to review/edit them
            if word.status == .flagged || word.status == .confirmed {
                sessionManager.selectWord(word)
            }
        }
    }
    
    private func wordBackgroundColor(for word: TranscribedWord) -> Color {
        switch word.status {
        case .clean: return .clear
        case .flagged: return Color.orange.opacity(0.15)
        case .confirmed: return Color.red.opacity(0.15)
        case .dismissed: return Color.gray.opacity(0.1)
        }
    }
    
    private func wordBorderColor(for word: TranscribedWord) -> Color {
        switch word.status {
        case .clean: return .clear
        case .flagged: return .orange
        case .confirmed: return .red
        case .dismissed: return .gray
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 12) {
            legendItem(color: .orange, label: "Flagged")
            legendItem(color: .red, label: "Confirmed")
            legendItem(color: .gray, label: "Dismissed")
        }
        .font(.caption2)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(color, lineWidth: 1)
                )
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Word Detail Panel
    
    private var wordDetailPanel: some View {
        Group {
            if let word = sessionManager.selectedWord {
                WordDetailView(word: word)
            } else {
                emptyDetailPanel
            }
        }
    }
    
    private var emptyDetailPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Select a Word")
                .font(.headline)
            
            Text("Tap on any word in the transcription to review, edit, or confirm errors.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            Text("**Analysis Assistant Only:** This tool provides automated suggestions to support your clinical workflow. All transcriptions and error patterns should be verified by the clinician. This tool does not make diagnostic determinations.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    TranscriptionView()
        .environmentObject(SessionManager())
}
