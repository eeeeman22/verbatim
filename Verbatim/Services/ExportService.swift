import Foundation
import UIKit
import PDFKit

/// Service for exporting session data to various formats
class ExportService {
    
    static let shared = ExportService()
    
    // MARK: - PDF Export
    
    /// Generate a PDF report for a session
    func generatePDFReport(for session: Session) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            let margin: CGFloat = 50
            let contentWidth = pageRect.width - (margin * 2)
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "Phonological Analysis Report"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Subtitle / Disclaimer
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            let disclaimer = "Analysis Assistant Tool - Not a Diagnostic Instrument"
            disclaimer.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: disclaimerAttributes)
            yPosition += 30
            
            // Session Info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            
            let sessionInfo = """
            Student: \(session.studentName.isEmpty ? "—" : session.studentName)
            Date: \(dateFormatter.string(from: session.date))
            Duration: \(formatDuration(session.duration))
            Total Words: \(session.totalWords)
            """
            
            let infoRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 80)
            sessionInfo.draw(in: infoRect, withAttributes: infoAttributes)
            yPosition += 90
            
            // Divider
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
            yPosition += 20
            
            // Error Pattern Summary
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            
            "Error Pattern Summary".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionTitleAttributes)
            yPosition += 25
            
            if session.confirmedErrors.isEmpty {
                "No errors confirmed during this session.".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: infoAttributes)
                yPosition += 20
            } else {
                let patternCounts = session.errorPatternCounts.sorted { $0.value > $1.value }
                
                for (pattern, count) in patternCounts {
                    let patternText = "• \(pattern.rawValue): \(count) occurrence\(count > 1 ? "s" : "")"
                    patternText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: infoAttributes)
                    yPosition += 18
                    
                    // Add description
                    let descAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.gray
                    ]
                    let descRect = CGRect(x: margin + 20, y: yPosition, width: contentWidth - 20, height: 30)
                    pattern.description.draw(in: descRect, withAttributes: descAttributes)
                    yPosition += 35
                }
            }
            
            yPosition += 10
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
            yPosition += 20
            
            // Confirmed Errors Detail
            "Confirmed Errors Log".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionTitleAttributes)
            yPosition += 25
            
            if session.confirmedErrors.isEmpty {
                "No errors logged.".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: infoAttributes)
                yPosition += 20
            } else {
                // Table header
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                
                let columns: [(String, CGFloat)] = [
                    ("Time", margin),
                    ("Word", margin + 60),
                    ("Target", margin + 140),
                    ("Produced", margin + 200),
                    ("Pattern", margin + 280)
                ]
                
                for (header, x) in columns {
                    header.draw(at: CGPoint(x: x, y: yPosition), withAttributes: headerAttributes)
                }
                yPosition += 18
                
                // Table rows
                let rowAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                
                for error in session.confirmedErrors {
                    // Check if we need a new page
                    if yPosition > pageRect.height - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    String(format: "%.2fs", error.timestamp).draw(at: CGPoint(x: columns[0].1, y: yPosition), withAttributes: rowAttributes)
                    error.word.draw(at: CGPoint(x: columns[1].1, y: yPosition), withAttributes: rowAttributes)
                    "/\(error.target)/".draw(at: CGPoint(x: columns[2].1, y: yPosition), withAttributes: rowAttributes)
                    "/\(error.produced)/".draw(at: CGPoint(x: columns[3].1, y: yPosition), withAttributes: rowAttributes)
                    error.pattern.rawValue.draw(at: CGPoint(x: columns[4].1, y: yPosition), withAttributes: rowAttributes)
                    yPosition += 16
                }
            }
            
            yPosition += 20
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
            yPosition += 20
            
            // Clinical Notes
            "Clinical Notes".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionTitleAttributes)
            yPosition += 25
            
            let notesText = session.clinicalNotes.isEmpty ? "No clinical notes recorded." : session.clinicalNotes
            let notesRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 150)
            notesText.draw(in: notesRect, withAttributes: infoAttributes)
            
            // Footer disclaimer
            let footerY = pageRect.height - 60
            yPosition = drawDivider(at: footerY, margin: margin, width: contentWidth, in: context)
            
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.gray
            ]
            let footer = """
            IMPORTANT: This analysis is provided as a clinical support tool only. Error pattern identification is based on 
            automated acoustic analysis and clinician-confirmed observations. All diagnostic decisions should be made by 
            a qualified speech-language pathologist based on comprehensive evaluation. This report does not constitute a diagnosis.
            """
            let footerRect = CGRect(x: margin, y: footerY + 10, width: contentWidth, height: 50)
            footer.draw(in: footerRect, withAttributes: footerAttributes)
        }
        
        return data
    }
    
    private func drawDivider(at y: CGFloat, margin: CGFloat, width: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return y
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%02ds", seconds, milliseconds)
        }
    }
    
    // MARK: - CSV Export
    
    /// Generate CSV data for errors
    func generateErrorsCSV(for session: Session) -> String {
        var csv = "Timestamp,Word,Target,Produced,Pattern,Phonetic,Expected,IsCustom,ConfirmedAt\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for error in session.confirmedErrors {
            let row = [
                String(format: "%.3f", error.timestamp),
                escapeCSV(error.word),
                escapeCSV(error.target),
                escapeCSV(error.produced),
                escapeCSV(error.pattern.rawValue),
                escapeCSV(error.phonetic),
                escapeCSV(error.expected),
                error.isCustom ? "true" : "false",
                dateFormatter.string(from: error.confirmedAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    /// Generate CSV data for full transcription
    func generateTranscriptionCSV(for session: Session) -> String {
        var csv = "Word,Confidence,StartTime,EndTime,Status,AutoPhonetic,ExpectedPhonetic,ManualPhonetic\n"
        
        for word in session.transcription {
            let row = [
                escapeCSV(word.text),
                String(format: "%.3f", word.confidence),
                String(format: "%.3f", word.startTime),
                String(format: "%.3f", word.endTime),
                word.status.rawValue,
                escapeCSV(word.autoPhonetic ?? ""),
                escapeCSV(word.expectedPhonetic ?? ""),
                escapeCSV(word.manualPhonetic ?? "")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    // MARK: - Clipboard
    
    /// Copy error summary to clipboard
    func copyErrorSummaryToClipboard(for session: Session) {
        var summary = "Phonological Error Summary\n"
        summary += "Student: \(session.studentName.isEmpty ? "—" : session.studentName)\n"
        summary += "Date: \(DateFormatter.localizedString(from: session.date, dateStyle: .medium, timeStyle: .short))\n\n"
        
        if session.confirmedErrors.isEmpty {
            summary += "No errors confirmed.\n"
        } else {
            summary += "Error Patterns:\n"
            for (pattern, count) in session.errorPatternCounts.sorted(by: { $0.value > $1.value }) {
                summary += "• \(pattern.rawValue): \(count)\n"
            }
            
            summary += "\nDetailed Errors:\n"
            for error in session.confirmedErrors {
                summary += "- \"\(error.word)\" at \(String(format: "%.2fs", error.timestamp)): /\(error.target)/ → /\(error.produced)/ (\(error.pattern.rawValue))\n"
            }
        }
        
        if !session.clinicalNotes.isEmpty {
            summary += "\nClinical Notes:\n\(session.clinicalNotes)\n"
        }
        
        summary += "\n---\nGenerated by Verbatim (Analysis Tool Only - Not a Diagnostic Instrument)"
        
        UIPasteboard.general.string = summary
    }
}
