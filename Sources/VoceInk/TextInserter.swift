import AppKit
import Foundation
import os

private let logger = Logger(subsystem: "com.voceink.app", category: "TextInserter")

struct TextInserter {

    enum Result {
        case pasted
        case copiedOnly(reason: String)
    }

    /// Inserisce il testo nel campo attivo simulando Cmd+V.
    /// Fallback: lascia il testo in pasteboard e notifica l'utente.
    @MainActor
    static func insert(_ text: String) async -> Result {
        let pasteboard = NSPasteboard.general

        // Salva il contenuto attuale della pasteboard
        let previousContents = pasteboard.string(forType: .string)

        // Imposta il testo nella pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Aspetta che il focus torni all'app precedente (il terminale)
        try? await Task.sleep(nanoseconds: 200_000_000)  // 200ms

        // Verifica permesso Accessibility
        let trusted = AXIsProcessTrusted()
        logger.info("AXIsProcessTrusted: \(trusted)")

        guard trusted else {
            logger.warning("Accessibility non abilitata, fallback copy-only")
            return .copiedOnly(reason: "Permesso Accessibility mancante. Testo copiato nella clipboard.")
        }

        // Simula Cmd+V
        let pasteResult = simulatePaste()
        logger.info("Paste result: \(String(describing: pasteResult))")

        if case .copiedOnly = pasteResult {
            return pasteResult
        }

        // Ripristina la pasteboard originale dopo un breve delay
        let savedChangeCount = pasteboard.changeCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if pasteboard.changeCount == savedChangeCount {
                pasteboard.clearContents()
                if let previous = previousContents {
                    pasteboard.setString(previous, forType: .string)
                }
            }
        }

        return .pasted
    }

    /// Simula Cmd+V via CGEvent.
    private static func simulatePaste() -> Result {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: Cmd+V (keycode 9 = 'v')
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            return .copiedOnly(reason: "Impossibile creare evento CGEvent key-down.")
        }
        keyDown.flags = .maskCommand

        // Key up: Cmd+V
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return .copiedOnly(reason: "Impossibile creare evento CGEvent key-up.")
        }
        keyUp.flags = .maskCommand

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
