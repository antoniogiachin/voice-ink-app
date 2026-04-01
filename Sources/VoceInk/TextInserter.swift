import AppKit
import Foundation

struct TextInserter {

    enum Result {
        case pasted
        case copiedOnly(reason: String)
    }

    /// Inserisce il testo nel campo attivo simulando Cmd+V.
    /// Fallback: lascia il testo in pasteboard e notifica l'utente.
    @MainActor
    static func insert(_ text: String) -> Result {
        let pasteboard = NSPasteboard.general

        // Salva il contenuto attuale della pasteboard
        let previousContents = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        // Imposta il testo nella pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Tenta Cmd+V via CGEvent
        guard let pasteResult = simulatePaste() else {
            return .copiedOnly(reason: "Impossibile simulare Cmd+V. Testo copiato nella clipboard.")
        }

        if case .copiedOnly = pasteResult {
            return pasteResult
        }

        // Ripristina la pasteboard originale dopo un breve delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Solo se nessun'altra app ha modificato la pasteboard nel frattempo
            if pasteboard.changeCount == previousChangeCount + 1 {
                pasteboard.clearContents()
                if let previous = previousContents {
                    pasteboard.setString(previous, forType: .string)
                }
            }
        }

        return .pasted
    }

    /// Simula Cmd+V via CGEvent.
    /// Richiede permesso Accessibility.
    private static func simulatePaste() -> Result? {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: Cmd+V (keycode 9 = 'v')
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            return .copiedOnly(reason: "Impossibile creare evento CGEvent.")
        }
        keyDown.flags = .maskCommand

        // Key up: Cmd+V
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return .copiedOnly(reason: "Impossibile creare evento CGEvent.")
        }
        keyUp.flags = .maskCommand

        // Invia gli eventi
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        return .pasted
    }

    /// Copia il testo nella pasteboard senza tentare il paste automatico.
    @MainActor
    static func copyOnly(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
