import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // View mode picker
                    Picker("View Mode", selection: $sessionManager.viewMode) {
                        Text("Transcription").tag(SessionManager.ViewMode.transcription)
                        HStack {
                            Text("Analysis")
                            if sessionManager.confirmedErrorsCount > 0 {
                                Text("\(sessionManager.confirmedErrorsCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                        .tag(SessionManager.ViewMode.analysis)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Main content
                    Group {
                        switch sessionManager.viewMode {
                        case .transcription:
                            TranscriptionView()
                        case .analysis:
                            AnalysisView()
                        }
                    }
                }
            }
            .navigationTitle("Verbatim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { sessionManager.startNewSession() }) {
                            Label("New Session", systemImage: "plus")
                        }
                        Button(action: { sessionManager.saveCurrentSession() }) {
                            Label("Save Session", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "folder")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportPDF) {
                            Label("Export PDF Report", systemImage: "doc.richtext")
                        }
                        Button(action: copyToClipboard) {
                            Label("Copy Summary", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func exportPDF() {
        guard let pdfData = ExportService.shared.generatePDFReport(for: sessionManager.currentSession) else {
            return
        }
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Verbatim_report.pdf")
        try? pdfData.write(to: tempURL)
        
        // Share
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func copyToClipboard() {
        ExportService.shared.copyErrorSummaryToClipboard(for: sessionManager.currentSession)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}
