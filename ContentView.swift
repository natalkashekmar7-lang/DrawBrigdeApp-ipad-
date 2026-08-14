import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bridge: BridgeState

    var body: some View {
        VStack(spacing: 20) {
            Text("DrawBridge — прототип")
                .font(.title2).bold()

            Text(bridge.status)
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()

            Text("Останнє повідомлення від PC:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(bridge.lastMessage)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
        }
        .padding()
    }
}
