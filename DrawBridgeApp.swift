import SwiftUI

@main
struct DrawBridgeApp: App {

    @StateObject private var bridge = BridgeState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bridge)
        }
    }
}

final class BridgeState: ObservableObject {
    @Published var status: String = "Не запущено"
    @Published var lastMessage: String = "—"

    private var listener: USBBridgeListener?

    init() {
        start()
    }

    func start() {
        let l = USBBridgeListener(port: 51234)
        l.onConnected = { [weak self] in
            DispatchQueue.main.async { self?.status = "З'єднано з PC" }
        }
        l.onDisconnected = { [weak self] in
            DispatchQueue.main.async { self?.status = "Слухаємо, з'єднання немає" }
        }
        l.onDataReceived = { [weak self] data in
            let text = String(data: data, encoding: .utf8) ?? "<\(data.count) байт>"
            DispatchQueue.main.async { self?.lastMessage = text }
        }
        l.start()
        listener = l
        status = "Слухаємо на порту 51234"
    }
}
