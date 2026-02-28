# Verbatim - Phonological Analysis Assistant

A native iOS app proof-of-concept for Speech-Language Pathologists to streamline phonological error documentation and analysis.

## ⚠️ Important Disclaimer

**This is a clinical support tool ONLY.** Verbatim does not make diagnostic determinations. All transcriptions, error patterns, and analyses should be verified by a qualified speech-language pathologist. This tool is designed to reduce tedious documentation work, not replace clinical judgment.

## Features

### Transcription View
- **Live Speech Recording** - Record student speech directly in the app
- **Automatic Transcription** - Uses Apple's on-device Speech Recognition API
- **Confidence-Based Flagging** - Words with low ASR confidence are automatically highlighted for review
- **Phonetic Analysis** - Low-confidence words show expected vs. detected pronunciation
- **Error Pattern Suggestions** - Common phonological processes are auto-detected (gliding, fronting, lisping, etc.)
- **IPA Keyboard** - Built-in IPA keyboard for manual transcription corrections

### Analysis View
- **Error Pattern Summary** - Aggregated view of all confirmed error patterns with occurrence counts
- **Confirmed Errors Log** - Detailed table of all clinician-confirmed errors
- **Clinical Notes** - Free-form text area for clinical observations
- **Export Options** - PDF reports, CSV data, clipboard copy

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Apple Developer account (for device deployment)

### Building the Project

1. **Open the Project**
   ```bash
   open Verbatim.xcodeproj
   ```

2. **Configure Signing**
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your development team
   - Xcode will automatically manage signing

3. **Run on Simulator**
   - Select an iOS 17+ simulator
   - Press Cmd+R or click the Play button
   - Note: Speech recognition works on simulator but may be less accurate than on-device

4. **Run on Device**
   - Connect your iOS device
   - Select it as the run destination
   - Press Cmd+R
   - Accept the speech recognition permission prompt

## Architecture

```
Verbatim/
├── VerbatimApp.swift          # App entry point
├── ContentView.swift            # Main container with tab navigation
├── Info.plist                   # App configuration & permissions
│
├── Views/
│   ├── TranscriptionView.swift  # Main transcription interface
│   ├── AnalysisView.swift       # Error analysis & export
│   ├── WordDetailView.swift     # Word detail panel
│   ├── IPAKeyboardView.swift    # Custom IPA input keyboard
│   └── RecordingControlsView.swift
│
├── Models/
│   └── Models.swift             # Data models (Word, Error, Session, etc.)
│
├── ViewModels/
│   └── TranscriptionViewModel.swift
│
├── Services/
│   ├── SpeechRecognitionService.swift  # Apple Speech framework wrapper
│   ├── AudioRecorderService.swift      # AVFoundation recording
│   ├── PronunciationDictionary.swift   # IPA lookup dictionary
│   ├── ErrorPatternAnalyzer.swift      # Phonological error detection
│   ├── SessionManager.swift            # State management
│   └── ExportService.swift             # PDF/CSV generation
│
└── Assets.xcassets/
```

## Key Technical Decisions

### On-Device Processing
All speech recognition uses Apple's on-device Speech framework. This ensures:
- **Privacy** - No audio leaves the device
- **FERPA Compliance** - Student data stays local
- **Offline Capability** - Works without internet

### Confidence-Based Workflow
- Words with ASR confidence < 0.7 are automatically flagged
- Flagged words get additional phonetic analysis
- SLPs review and confirm/dismiss each flag
- Clean words display as standard text

### Simulated Phoneme Detection
In this proof-of-concept, the "detected phonetic" output is simulated based on common error patterns. In a production app, you would integrate:
- **wav2vec2-phoneme** via Core ML for actual phoneme recognition
- **WhisperKit** for higher-accuracy transcription
- A proper phoneme alignment algorithm

## Extending the App

### Adding Real Phoneme Recognition

1. Convert wav2vec2-phoneme to Core ML:
   ```python
   # Using coremltools
   import coremltools as ct
   from transformers import Wav2Vec2ForCTC
   
   model = Wav2Vec2ForCTC.from_pretrained("facebook/wav2vec2-lv-60-espeak-cv-ft")
   # ... conversion code
   ```

2. Extract audio segments for low-confidence words
3. Run through the phoneme model
4. Compare to expected pronunciation from dictionary

### Expanding the Pronunciation Dictionary

The built-in dictionary covers ~150 common words. To expand:

1. Download CMU Pronouncing Dictionary
2. Convert ARPAbet to IPA using the provided converter
3. Bundle as a JSON file or SQLite database

### Adding Student Profiles

The data models support this - add:
- Student-specific target phonemes
- Historical error tracking
- Progress visualization

## Privacy & Compliance Notes

- All processing is on-device
- Audio files are stored locally in the app's documents directory
- Sessions can be exported and then deleted
- No user accounts or cloud sync (by design)

For school deployment, consult with your IT department about:
- MDM deployment
- Data retention policies
- FERPA documentation requirements

## License

This is a proof-of-concept for educational purposes. 

---

Built with ❤️ for Speech-Language Pathologists
