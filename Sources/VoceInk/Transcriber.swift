import Foundation
import os

private let logger = Logger(subsystem: "com.voceink.app", category: "Transcriber")

final class Transcriber {
    private let settings: SettingsManager
    private var currentProcess: Process?
    private let timeoutSeconds: Double = 120

    init(settings: SettingsManager) {
        self.settings = settings
    }

    /// Trascrive un file audio WAV usando whisper-cli.
    /// Ritorna il testo raw trascritto. Timeout dopo 120s.
    func transcribe(audioURL: URL) async throws -> String {
        let whisperPath = settings.whisperCLIPath
        let modelPath = settings.modelPath

        logger.info("whisper-cli path: \(whisperPath)")
        logger.info("model path: \(modelPath)")

        guard FileManager.default.fileExists(atPath: whisperPath) else {
            logger.error("whisper-cli NOT FOUND at: \(whisperPath)")
            throw TranscriberError.whisperNotFound(whisperPath)
        }
        guard FileManager.default.fileExists(atPath: modelPath) else {
            logger.error("model NOT FOUND at: \(modelPath)")
            throw TranscriberError.modelNotFound(modelPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = [
            "-m", modelPath,
            "-l", "it",
            "-f", audioURL.path,
            "--no-timestamps",
            "-t", "\(ProcessInfo.processInfo.activeProcessorCount)",
            "--print-special", "false",
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        currentProcess = process

        // Timeout: termina il processo se impiega troppo
        let timeoutTask = Task { [weak self, timeoutSeconds] in
            try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            if let proc = self?.currentProcess, proc.isRunning {
                logger.warning("Timeout raggiunto (\(timeoutSeconds)s), terminazione processo whisper-cli")
                proc.terminate()
            }
        }

        defer {
            timeoutTask.cancel()
            currentProcess = nil
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { proc in
                    let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: outputData, encoding: .utf8) ?? ""

                    if proc.terminationStatus != 0 {
                        let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                        continuation.resume(
                            throwing: TranscriberError.processFailed(
                                code: proc.terminationStatus,
                                stderr: errorOutput
                            ))
                        return
                    }

                    let text = Self.parseOutput(output)
                    continuation.resume(returning: text)
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: TranscriberError.launchFailed(error))
                }
            }
        } onCancel: {
            // Se il Task viene cancellato (es. app chiusa), termina il processo
            if process.isRunning {
                logger.info("Task cancellato, terminazione processo whisper-cli")
                process.terminate()
            }
        }
    }

    /// Termina il processo in corso (se presente).
    func cancel() {
        if let process = currentProcess, process.isRunning {
            process.terminate()
            currentProcess = nil
        }
    }

    /// Parse dell'output di whisper-cli: rimuove righe vuote, whitespace extra e token speciali
    static func parseOutput(_ raw: String) -> String {
        var result = raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Rimuovi token speciali di whisper (es. [_EOT_], [_BEG_], [_SOT_], [BLANK_AUDIO])
        result = result.replacingOccurrences(
            of: "\\[_?[A-Z_]+_?\\]",
            with: "",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TranscriberError: LocalizedError {
    case whisperNotFound(String)
    case modelNotFound(String)
    case processFailed(code: Int32, stderr: String)
    case launchFailed(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .whisperNotFound(let path):
            return "whisper-cli non trovato: \(path). Esegui scripts/setup.sh"
        case .modelNotFound(let path):
            return "Modello non trovato: \(path). Esegui scripts/setup.sh"
        case .processFailed(let code, let stderr):
            return "whisper-cli terminato con codice \(code): \(stderr)"
        case .launchFailed(let error):
            return "Impossibile avviare whisper-cli: \(error.localizedDescription)"
        case .timeout:
            return "Trascrizione interrotta: timeout raggiunto."
        }
    }
}
