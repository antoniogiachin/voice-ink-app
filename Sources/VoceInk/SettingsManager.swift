import Carbon
import Foundation

/// Gestisce le impostazioni persistenti dell'app tramite UserDefaults.
final class SettingsManager: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hotKeyCode = "hotKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let outputMode = "outputMode"
        static let whisperCLIPath = "whisperCLIPath"
        static let modelPath = "modelPath"
    }

    // MARK: - Hotkey

    @Published var hotKeyCode: UInt32 {
        didSet { defaults.set(hotKeyCode, forKey: Keys.hotKeyCode) }
    }

    @Published var hotKeyModifiers: UInt32 {
        didSet { defaults.set(hotKeyModifiers, forKey: Keys.hotKeyModifiers) }
    }

    // MARK: - Output mode

    @Published var outputMode: OutputMode {
        didSet { defaults.set(outputMode.rawValue, forKey: Keys.outputMode) }
    }

    // MARK: - Paths

    @Published var whisperCLIPath: String {
        didSet { defaults.set(whisperCLIPath, forKey: Keys.whisperCLIPath) }
    }

    @Published var modelPath: String {
        didSet { defaults.set(modelPath, forKey: Keys.modelPath) }
    }

    // MARK: - Init

    init() {
        // Calcola path di default relativi all'app bundle o alla directory di lavoro
        let bundlePath = Bundle.main.bundlePath
        let appDir: String
        if bundlePath.hasSuffix(".app") {
            // Dentro un .app bundle
            appDir =
                URL(fileURLWithPath: bundlePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .path
        } else {
            // Sviluppo: usa la directory corrente
            appDir = FileManager.default.currentDirectoryPath
        }

        let defaultWhisperPath =
            (appDir as NSString).appendingPathComponent("whisper.cpp/build/bin/whisper-cli")
        let defaultModelPath =
            (appDir as NSString).appendingPathComponent("models/ggml-medium.bin")

        // Carica da UserDefaults con fallback ai default
        let storedKeyCode = UInt32(defaults.integer(forKey: Keys.hotKeyCode))
        self.hotKeyCode = storedKeyCode != 0 ? storedKeyCode : UInt32(kVK_Space)

        let storedMods = defaults.integer(forKey: Keys.hotKeyModifiers)
        self.hotKeyModifiers =
            storedMods != 0 ? UInt32(storedMods) : UInt32(controlKey | shiftKey)

        if let modeStr = defaults.string(forKey: Keys.outputMode),
            let mode = OutputMode(rawValue: modeStr)
        {
            self.outputMode = mode
        } else {
            self.outputMode = .libero
        }

        self.whisperCLIPath =
            defaults.string(forKey: Keys.whisperCLIPath) ?? defaultWhisperPath
        self.modelPath =
            defaults.string(forKey: Keys.modelPath) ?? defaultModelPath
    }

    /// Lista dei modelli .bin disponibili nella directory models/
    var availableModels: [String] {
        let modelsDir =
            (modelPath as NSString).deletingLastPathComponent
        guard
            let files = try? FileManager.default.contentsOfDirectory(atPath: modelsDir)
        else {
            return []
        }
        return files.filter { $0.hasSuffix(".bin") }.sorted()
    }

    /// Seleziona un modello diverso dalla lista available.
    func selectModel(_ filename: String) {
        let modelsDir =
            (modelPath as NSString).deletingLastPathComponent
        modelPath = (modelsDir as NSString).appendingPathComponent(filename)
    }
}
