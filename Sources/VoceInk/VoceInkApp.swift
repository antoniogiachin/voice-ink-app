import SwiftUI

@main
struct VoceInkApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            let icon = appState.status == .recording
                ? AppIcon.menuBarRecordingIcon()
                : AppIcon.menuBarIcon()
            Image(nsImage: icon)
        }

        Window("Impostazioni VoceInk", id: "settings") {
            SettingsView(
                settings: appState.settings,
                onHotKeyChanged: { appState.updateHotKey() }
            )
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Stato attuale
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.status.statusText)
                    .font(.headline)
            }

            Divider()

            // Ultima trascrizione
            if !appState.lastTranscription.isEmpty {
                Text(appState.lastTranscription)
                    .font(.caption)
                    .lineLimit(4)
                    .frame(maxWidth: 300, alignment: .leading)

                Button("Copia ultimo testo") {
                    TextInserter.copyOnly(appState.lastTranscription)
                }

                Divider()
            }

            // Toggle modalità
            Picker("Modalita'", selection: $appState.settings.outputMode) {
                ForEach(OutputMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Divider()

            // Azioni
            Button("Impostazioni...") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Esci") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(4)
        .onAppear {
            appState.setup()
        }
    }

    private var statusColor: Color {
        switch appState.status {
        case .idle: return .gray
        case .recording: return .red
        case .transcribing: return .orange
        case .pasted: return .green
        case .error: return .red
        }
    }
}
