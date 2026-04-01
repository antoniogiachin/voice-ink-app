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
    @Published var recordingDuration: TimeInterval = 0

    var settings = SettingsManager()
    let recorder = AudioRecorder()
    private lazy var transcriber = Transcriber(settings: settings)
    private let hotKeyManager = HotKeyManager()
    private let overlayController = OverlayWindowController()

    private var recordingURL: URL?
    private var recordingTimer: Timer?
    private var transcriptionTask: Task<Void, Never>?
    private var isSetUp = false

    func setup() {
        guard !isSetUp else { return }
        isSetUp = true
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
            break
        }
    }

    private func startRecording() {
        do {
            let url = try recorder.startRecording()
            recordingURL = url
            status = .recording

            // Avvia timer durata — DOPO che la registrazione è partita con successo
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.recordingDuration += 1
                }
            }

            // Mostra overlay
            overlayController.show(appState: self)
        } catch {
            // Se fallisce, pulisci tutto quello che potrebbe essere rimasto
            stopRecordingTimerAndOverlay()
            recorder.cleanup()
            status = .error(error.localizedDescription)
            resetAfterDelay()
        }
    }

    private func stopAndTranscribe() {
        // Ferma timer e overlay immediatamente
        stopRecordingTimerAndOverlay()

        guard let url = recorder.stopRecording() else {
            status = .error("Nessuna registrazione attiva")
            resetAfterDelay()
            return
        }

        status = .transcribing

        transcriptionTask = Task { [weak self] in
            guard let self else { return }

            defer {
                // Cleanup SEMPRE eseguito, anche se il Task viene cancellato
                self.recorder.cleanup()
            }

            do {
                let rawText = try await self.transcriber.transcribe(audioURL: url)

                // Verifica cancellazione dopo l'await
                guard !Task.isCancelled else { return }

                let processed = TextProcessor.process(rawText, mode: self.settings.outputMode)

                if processed.isEmpty {
                    self.status = .error("Nessun testo riconosciuto")
                    self.resetAfterDelay()
                    return
                }

                self.lastTranscription = processed
                let result = await TextInserter.insert(processed)

                switch result {
                case .pasted:
                    self.status = .pasted
                case .copiedOnly(let reason):
                    self.status = .pasted
                    print("[VoceInk] Fallback copy-only: \(reason)")
                }

                self.resetAfterDelay()
            } catch {
                guard !Task.isCancelled else { return }
                self.status = .error(error.localizedDescription)
                self.resetAfterDelay()
            }
        }
    }

    /// Ferma timer registrazione e nascondi overlay. Chiamato su ogni uscita dalla registrazione.
    private func stopRecordingTimerAndOverlay() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        overlayController.hide()
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
