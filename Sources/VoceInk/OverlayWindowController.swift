import AppKit
import SwiftUI

/// Controller per la finestra floating dell'overlay di registrazione.
/// NSPanel non attivante: non ruba il focus dal terminale.
final class OverlayWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<RecordingOverlayView>?

    func show(appState: AppState) {
        guard panel == nil else {
            panel?.orderFront(nil)
            return
        }

        let overlayView = RecordingOverlayView(appState: appState)
        let hosting = NSHostingView(rootView: overlayView)
        hosting.frame = NSRect(x: 0, y: 0, width: 160, height: 100)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = false

        // Posiziona in alto al centro dello schermo
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 80
            let y = screenFrame.maxY - 120
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)

        self.panel = panel
        self.hostingView = hosting
    }

    func hide() {
        panel?.close()
        panel = nil
        hostingView = nil
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }
}
