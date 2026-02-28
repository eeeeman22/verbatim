import SwiftUI

struct IPAKeyboardView: View {
    @Binding var text: String
    var onDismiss: () -> Void
    
    @State private var selectedTab: KeyboardTab = .consonants
    
    enum KeyboardTab: String, CaseIterable {
        case consonants = "Consonants"
        case vowels = "Vowels"
        case diacritics = "Diacritics"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("IPA Keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Hide") {
                    onDismiss()
                }
                .font(.caption)
            }
            
            // Tab picker
            Picker("Category", selection: $selectedTab) {
                ForEach(KeyboardTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            // Keys
            VStack(spacing: 6) {
                switch selectedTab {
                case .consonants:
                    ForEach(IPAKeyboard.consonants, id: \.self) { row in
                        keyRow(symbols: row)
                    }
                case .vowels:
                    ForEach(IPAKeyboard.vowels, id: \.self) { row in
                        keyRow(symbols: row)
                    }
                case .diacritics:
                    keyRow(symbols: IPAKeyboard.diacritics)
                }
            }
            
            // Control buttons
            HStack(spacing: 8) {
                Button(action: deleteLastCharacter) {
                    HStack {
                        Image(systemName: "delete.left")
                        Text("Delete")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                Button(action: clearAll) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Button(action: addSlashes) {
                    Text("/ /")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Button(action: addSpace) {
                    Text("Space")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func keyRow(symbols: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(symbols, id: \.self) { symbol in
                keyButton(symbol: symbol)
            }
        }
    }
    
    private func keyButton(symbol: String) -> some View {
        Button(action: { insertSymbol(symbol) }) {
            Text(symbol)
                .font(.system(.title3, design: .monospaced))
                .frame(minWidth: 36, minHeight: 36)
                .background(Color(.systemBackground))
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    private func insertSymbol(_ symbol: String) {
        text += symbol
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func deleteLastCharacter() {
        if !text.isEmpty {
            text.removeLast()
        }
    }
    
    private func clearAll() {
        text = ""
    }
    
    private func addSlashes() {
        if text.isEmpty {
            text = "/ /"
        } else if !text.hasPrefix("/") {
            text = "/\(text)/"
        }
    }
    
    private func addSpace() {
        text += " "
    }
}

// MARK: - Quick IPA Picker

struct QuickIPAPicker: View {
    @Binding var selectedSymbol: String?
    var symbols: [String]
    var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button(action: { selectedSymbol = symbol }) {
                            Text(symbol)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedSymbol == symbol
                                        ? Color.blue
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundColor(
                                    selectedSymbol == symbol
                                        ? .white
                                        : .primary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Common Substitution Pairs

struct CommonSubstitutionPairs {
    static let gliding = [
        ("ɹ", "w"),
        ("l", "w"),
        ("ɹ", "j"),
        ("l", "j")
    ]
    
    static let fronting = [
        ("k", "t"),
        ("ɡ", "d"),
        ("ŋ", "n")
    ]
    
    static let stopping = [
        ("f", "p"),
        ("v", "b"),
        ("s", "t"),
        ("z", "d"),
        ("θ", "t"),
        ("ð", "d"),
        ("ʃ", "t"),
        ("ʒ", "d")
    ]
    
    static let lisping = [
        ("s", "θ"),
        ("z", "ð")
    ]
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        
        var body: some View {
            VStack {
                Text("Current: \(text)")
                    .font(.headline)
                
                IPAKeyboardView(text: $text, onDismiss: {})
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
