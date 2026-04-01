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

        let file = try AVAudioFile(
            forWriting: url,
            settings: recordingFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Converter dal formato del microfono al formato richiesto da whisper
        guard let converter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
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

        try engine.start()

        self.audioEngine = engine
        self.audioFile = file
        self.recordingURL = url
        self.isRecording = true

        return url
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        isRecording = false
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil

        return recordingURL
    }

    func cleanup() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
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
