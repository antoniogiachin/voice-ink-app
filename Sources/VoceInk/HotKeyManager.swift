import Carbon
import Foundation

/// Gestisce la registrazione di una hotkey globale tramite le API Carbon.
/// Default: Ctrl+Shift+Space (toggle recording).
final class HotKeyManager {
    typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onToggle: Handler?

    // Singleton necessario per il callback C di Carbon
    static var shared: HotKeyManager?

    private var keyCode: UInt32
    private var modifiers: UInt32

    init(keyCode: UInt32 = UInt32(kVK_Space), modifiers: UInt32 = UInt32(controlKey | shiftKey)) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        HotKeyManager.shared = self
    }

    func register(onToggle: @escaping Handler) {
        self.onToggle = onToggle

        // Installa event handler per hot key
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            print("[VoceInk] Errore installazione event handler: \(status)")
            return
        }

        // Registra la hotkey
        let hotKeyID = EventHotKeyID(signature: fourCharCode("VCIK"), id: 1)
        var ref: EventHotKeyRef?

        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard regStatus == noErr else {
            print("[VoceInk] Errore registrazione hotkey: \(regStatus)")
            return
        }

        self.hotKeyRef = ref
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        guard let onToggle = self.onToggle else { return }
        unregister()
        self.keyCode = keyCode
        self.modifiers = modifiers
        register(onToggle: onToggle)
    }

    fileprivate func handleHotKey() {
        onToggle?()
    }

    deinit {
        unregister()
    }
}

/// Callback C per Carbon event handler
private func hotKeyCallback(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    HotKeyManager.shared?.handleHotKey()
    return noErr
}

/// Converte una stringa di 4 caratteri in OSType (FourCharCode)
private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = (result << 8) | OSType(char)
    }
    return result
}
