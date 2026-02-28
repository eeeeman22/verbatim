import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var clinicalNotes: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // iPad layout
                HStack(spacing: 0) {
                    // Main content
                    ScrollView {
                        mainContent
                    }
                    .frame(width: geometry.size.width * 0.65)
                    
                    Divider()
                    
                    // Export panel
                    exportPanel
                        .frame(width: geometry.size.width * 0.35)
                }
            } else {
                // iPhone layout
                ScrollView {
                    VStack(spacing: 16) {
                        mainContent
                        
                        exportSection
                    }
                }
            }
        }
        .onAppear {
            clinicalNotes = sessionManager.currentSession.clinicalNotes
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Error Pattern Summary
            errorPatternSummary
            
            // Confirmed Errors Log
            confirmedErrorsLog
            
            // Clinical Notes
            clinicalNotesSection
            
            // Disclaimer
            disclaimerBanner
        }
        .padding()
    }
    
    // MARK: - Error Pattern Summary
    
    private var errorPatternSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Error Pattern Summary")
                .font(.headline)
            
            if sessionManager.currentSession.confirmedErrors.isEmpty {
                emptyPatternState
            } else {
                patternCards
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var emptyPatternState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No errors confirmed yet")
                .foregroundColor(.secondary)
            
            Text("Switch to Transcription view to review flagged words.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var patternCards: some View {
        VStack(spacing: 12) {
            let sortedPatterns = sessionManager.currentSession.errorPatternCounts.sorted { $0.value > $1.value }
            
            ForEach(sortedPatterns, id: \.key) { pattern, count in
                patternCard(pattern: pattern, count: count)
            }
        }
    }
    
    private func patternCard(pattern: ErrorPattern, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(count) occurrence\(count > 1 ? "s" : "")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            
            Text(pattern.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Show affected words
            let affectedErrors = sessionManager.currentSession.confirmedErrors.filter { $0.pattern == pattern }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(affectedErrors) { error in
                        HStack(spacing: 4) {
                            Text(error.word)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(error.phonetic)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.red)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Confirmed Errors Log
    
    private var confirmedErrorsLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirmed Errors Log")
                .font(.headline)
            
            if sessionManager.currentSession.confirmedErrors.isEmpty {
                Text("No errors logged yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                errorsTable
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var errorsTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Time")
                    .frame(width: 50, alignment: .leading)
                Text("Word")
                    .frame(width: 70, alignment: .leading)
                Text("Target")
                    .frame(width: 50, alignment: .leading)
                Text("Produced")
                    .frame(width: 60, alignment: .leading)
                Text("Pattern")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                    .frame(width: 30)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            
            // Rows
            ForEach(Array(sessionManager.currentSession.confirmedErrors.enumerated()), id: \.element.id) { index, error in
                HStack {
                    Text(String(format: "%.2fs", error.timestamp))
                        .frame(width: 50, alignment: .leading)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text(error.word)
                        .frame(width: 70, alignment: .leading)
                        .fontWeight(.medium)
                    
                    Text("/\(error.target)/")
                        .frame(width: 50, alignment: .leading)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("/\(error.produced)/")
                        .frame(width: 60, alignment: .leading)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text(error.pattern.rawValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Button(action: { removeError(error) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 30)
                }
                .font(.caption)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(index % 2 == 0 ? Color(.systemBackground) : Color(.secondarySystemBackground).opacity(0.5))
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func removeError(_ error: ConfirmedError) {
        sessionManager.removeError(error)
    }
    
    // MARK: - Clinical Notes
    
    private var clinicalNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clinical Notes")
                .font(.headline)
            
            TextEditor(text: $clinicalNotes)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .onChange(of: clinicalNotes) { _, newValue in
                    sessionManager.updateClinicalNotes(newValue)
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Export Panel (iPad)
    
    private var exportPanel: some View {
        VStack(spacing: 20) {
            Text("Export Session")
                .font(.headline)
            
            exportButtons
            
            Divider()
            
            quickStats
            
            Divider()
            
            sessionInfo
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Export Section (iPhone)
    
    private var exportSection: some View {
        VStack(spacing: 12) {
            Text("Export")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            exportButtons
            
            HStack(spacing: 16) {
                quickStats
                sessionInfo
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var exportButtons: some View {
        VStack(spacing: 8) {
            Button(action: exportPDF) {
                Label("Export PDF Report", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: copyToClipboard) {
                Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            
            Button(action: exportCSV) {
                Label("Export CSV Data", systemImage: "tablecells")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Stats")
                .font(.subheadline)
                .fontWeight(.medium)
            
            statRow(label: "Total Words", value: "\(sessionManager.currentSession.totalWords)")
            statRow(label: "Flagged Words", value: "\(sessionManager.flaggedWordsCount)", color: .orange)
            statRow(label: "Confirmed Errors", value: "\(sessionManager.confirmedErrorsCount)", color: .red)
            statRow(label: "Error Patterns", value: "\(sessionManager.errorPatternCounts.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    private var sessionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Info")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let session = sessionManager.currentSession
            
            Group {
                infoRow(label: "Student", value: session.studentName.isEmpty ? "—" : session.studentName)
                infoRow(label: "Date", value: DateFormatter.localizedString(from: session.date, dateStyle: .medium, timeStyle: .none))
                infoRow(label: "Duration", value: formatDuration(session.duration))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("**Important:** This analysis is provided as a clinical support tool only. Error pattern identification is based on automated acoustic analysis and clinician-confirmed observations. All diagnostic decisions should be made by a qualified speech-language pathologist based on comprehensive evaluation. This report does not constitute a diagnosis.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func exportPDF() {
        guard let pdfData = ExportService.shared.generatePDFReport(for: sessionManager.currentSession) else {
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Verbatim_Report.pdf")
        try? pdfData.write(to: tempURL)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func copyToClipboard() {
        ExportService.shared.copyErrorSummaryToClipboard(for: sessionManager.currentSession)
    }
    
    private func exportCSV() {
        let csv = ExportService.shared.generateErrorsCSV(for: sessionManager.currentSession)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Verbatim_Errors.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return String(format: "%.2fs", duration)
        }
    }
}

#Preview {
    AnalysisView()
        .environmentObject(SessionManager())
}
