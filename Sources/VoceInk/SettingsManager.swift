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
        let defaultWhisperPath: String
        let defaultModelPath: String

        // 1. Cerca dentro il bundle (Contents/Resources/) — build.sh li copia lì
        let bundleResources = Bundle.main.resourceURL?.path ?? ""
        let bundleWhisper = (bundleResources as NSString).appendingPathComponent("whisper-cli")
        let bundleModel = (bundleResources as NSString).appendingPathComponent("ggml-medium.bin")

        if FileManager.default.fileExists(atPath: bundleWhisper) {
            defaultWhisperPath = bundleWhisper
            defaultModelPath = bundleModel
        } else {
            // 2. Cerca risalendo dal bundle fino alla root del progetto
            var candidate = URL(fileURLWithPath: Bundle.main.bundlePath)
            var projectDir: String? = nil
            for _ in 0..<5 {
                candidate = candidate.deletingLastPathComponent()
                let check = candidate.appendingPathComponent("whisper.cpp/build/bin/whisper-cli").path
                if FileManager.default.fileExists(atPath: check) {
                    projectDir = candidate.path
                    break
                }
            }
            let base = projectDir ?? FileManager.default.currentDirectoryPath
            defaultWhisperPath = (base as NSString).appendingPathComponent("whisper.cpp/build/bin/whisper-cli")
            defaultModelPath = (base as NSString).appendingPathComponent("models/ggml-medium.bin")
        }

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
