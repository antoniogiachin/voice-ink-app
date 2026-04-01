import Carbon
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    var onHotKeyChanged: (() -> Void)?

    var body: some View {
        Form {
            Section("Modalita' output") {
                Picker("Modalita'", selection: $settings.outputMode) {
                    ForEach(OutputMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch settings.outputMode {
                case .libero:
                    Text("Corregge punteggiatura, maiuscole e refusi evidenti.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .promptCodex:
                    Text("Rende il testo piu' chiaro e operativo, rimuove filler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Modello Whisper") {
                let models = settings.availableModels
                if models.isEmpty {
                    Text("Nessun modello trovato. Esegui scripts/setup.sh")
                        .foregroundStyle(.red)
                } else {
                    Picker(
                        "Modello",
                        selection: Binding(
                            get: {
                                (settings.modelPath as NSString).lastPathComponent
                            },
                            set: { newValue in
                                settings.selectModel(newValue)
                            }
                        )
                    ) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }

                TextField("Path whisper-cli", text: $settings.whisperCLIPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Hotkey") {
                HStack {
                    Text("Hotkey attuale:")
                    Text(hotKeyDescription)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text("Per cambiare la hotkey, modifica i valori nelle preferenze.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 360)
        .navigationTitle("VoceInk - Impostazioni")
    }

    private var hotKeyDescription: String {
        var parts: [String] = []
        let mods = settings.hotKeyModifiers
        if mods & UInt32(controlKey) != 0 { parts.append("Ctrl") }
        if mods & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if mods & UInt32(optionKey) != 0 { parts.append("Option") }
        if mods & UInt32(cmdKey) != 0 { parts.append("Cmd") }

        let keyName: String
        switch Int(settings.hotKeyCode) {
        case kVK_Space: keyName = "Space"
        case kVK_Return: keyName = "Return"
        case kVK_Tab: keyName = "Tab"
        default: keyName = "Key(\(settings.hotKeyCode))"
        }
        parts.append(keyName)
        return parts.joined(separator: " + ")
    }
}
