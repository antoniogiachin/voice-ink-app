import Combine
import SwiftUI

/// Vista overlay con barre equalizzatore animate e timer di registrazione.
/// I timer vengono creati solo quando la view appare e cancellati quando scompare.
struct RecordingOverlayView: View {
    @ObservedObject var appState: AppState

    private let barCount = 9
    @State private var barHeights: [CGFloat] = Array(repeating: 0.3, count: 9)
    @State private var dotVisible = true
    @State private var timerCancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 8) {
            // Barre equalizzatore
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 6, height: barHeights[index] * 40)
                        .animation(.easeInOut(duration: 0.15), value: barHeights[index])
                }
            }
            .frame(height: 40)

            // REC + Timer
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(dotVisible ? 1.0 : 0.3)

                Text("REC")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.red)

                Spacer()

                Text(formatDuration(appState.recordingDuration))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 160)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .onAppear {
            startTimers()
        }
        .onDisappear {
            stopTimers()
        }
    }

    private func startTimers() {
        // Barre equalizzatore: aggiorna ogni 0.15s
        Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard appState.status == .recording else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    for i in 0..<barCount {
                        barHeights[i] = CGFloat.random(in: 0.15...1.0)
                    }
                }
            }
            .store(in: &timerCancellables)

        // Pallino REC pulsante
        Timer.publish(every: 0.6, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                dotVisible.toggle()
            }
            .store(in: &timerCancellables)
    }

    private func stopTimers() {
        timerCancellables.removeAll()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
