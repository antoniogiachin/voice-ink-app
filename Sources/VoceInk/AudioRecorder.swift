import AVFoundation
import Foundation

final class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private(set) var isRecording = false

    /// Formato richiesto da whisper.cpp: 16kHz, mono, PCM 16-bit
    private let sampleRate: Double = 16000
    private let channels: AVAudioChannelCount = 1

    func startRecording() throws -> URL {
        // Pulisci eventuale stato precedente rimasto
        stopAndRelease()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let tempDir = NSTemporaryDirectory()
        let fileName = "voceink_\(Int(Date().timeIntervalSince1970)).wav"
        let url = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)

        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        )!

        let file: AVAudioFile
        do {
            file = try AVAudioFile(
                forWriting: url,
                settings: recordingFormat.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: true
            )
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            try? FileManager.default.removeItem(at: url)
            throw AudioRecorderError.converterCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, self.isRecording else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * self.sampleRate / inputFormat.sampleRate
            )
            guard frameCount > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: recordingFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if status == .haveData, convertedBuffer.frameLength > 0 {
                try? file.write(from: convertedBuffer)
            }
        }

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            try? FileManager.default.removeItem(at: url)
            throw error
        }

        self.audioEngine = engine
        self.audioFile = file
        self.recordingURL = url
        self.isRecording = true

        return url
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        stopAndRelease()
        return recordingURL
    }

    func cleanup() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }

    /// Ferma engine, rimuovi tap, rilascia risorse audio.
    private func stopAndRelease() {
        isRecording = false
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil
        audioFile = nil
    }
}

enum AudioRecorderError: LocalizedError {
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Impossibile creare il converter audio per il formato 16kHz mono."
        }
    }
}
