import Foundation
import SwiftUI

enum AppStatus: Equatable {
    case idle
    case recording
    case transcribing
    case pasted
    case error(String)

    var iconName: String {
        switch self {
        case .idle: return "mic.slash"
        case .recording: return "mic.fill"
        case .transcribing: return "text.bubble"
        case .pasted: return "checkmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "Pronto"
        case .recording: return "Registrazione..."
        case .transcribing: return "Trascrizione..."
        case .pasted: return "Testo inserito"
        case .error(let msg): return "Errore: \(msg)"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var status: AppStatus = .idle
    @Published var lastTranscription: String = ""

    var settings = SettingsManager()
    let recorder = AudioRecorder()
    private lazy var transcriber = Transcriber(settings: settings)
    private let hotKeyManager = HotKeyManager()

    private var recordingURL: URL?

    func setup() {
        hotKeyManager.register { [weak self] in
            DispatchQueue.main.async {
                self?.toggleRecording()
            }
        }
    }

    func toggleRecording() {
        switch status {
        case .recording:
            stopAndTranscribe()
        case .idle, .pasted, .error:
            startRecording()
        case .transcribing:
            break  // Ignora durante trascrizione
        }
    }

    private func startRecording() {
        do {
            let url = try recorder.startRecording()
            recordingURL = url
            status = .recording
        } catch {
            status = .error(error.localizedDescription)
            resetAfterDelay()
        }
    }

    private func stopAndTranscribe() {
        guard let url = recorder.stopRecording() else {
            status = .error("Nessuna registrazione attiva")
            resetAfterDelay()
            return
        }

        status = .transcribing

        Task {
            do {
                let rawText = try await transcriber.transcribe(audioURL: url)
                let processed = TextProcessor.process(rawText, mode: settings.outputMode)

                recorder.cleanup()

                if processed.isEmpty {
                    status = .error("Nessun testo riconosciuto")
                    resetAfterDelay()
                    return
                }

                lastTranscription = processed
                let result = TextInserter.insert(processed)

                switch result {
                case .pasted:
                    status = .pasted
                case .copiedOnly(let reason):
                    status = .pasted
                    print("[VoceInk] Fallback copy-only: \(reason)")
                }

                resetAfterDelay()
            } catch {
                recorder.cleanup()
                status = .error(error.localizedDescription)
                resetAfterDelay()
            }
        }
    }

    private func resetAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            if case .pasted = self.status { self.status = .idle }
            if case .error = self.status { self.status = .idle }
        }
    }

    func updateHotKey() {
        hotKeyManager.updateHotKey(
            keyCode: settings.hotKeyCode,
            modifiers: settings.hotKeyModifiers
        )
    }
}
