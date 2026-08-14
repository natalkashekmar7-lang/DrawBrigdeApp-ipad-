//
//  USBBridgeListener.swift
//
//  Прототип TCP-сервера на iPad, який слухає з'єднання від Windows-клієнта
//  (по Wi-Fi одразу, по USB — коли піднятий тунель через windows_usb_bridge.py).
//
//  Потребує: проєкт у Xcode (Mac для збірки та встановлення на iPad),
//  таргет iOS/iPadOS, дозвіл "Local Network" в Info.plist:
//
//    <key>NSLocalNetworkUsageDescription</key>
//    <string>Потрібно для з'єднання з Windows-комп'ютером</string>
//    <key>NSBonjourServices</key>
//    <array>
//        <string>_drawbridge._tcp</string>
//    </array>
//
//  Це лише транспортний прошарок. Дані пера (тиск/нахил) читаються окремо
//  через UITouch / PencilKit і серіалізуються в JSON або бінарний формат
//  перед відправкою через `send(data:)`.

import Foundation
import Network

final class USBBridgeListener {

    private var listener: NWListener?
    private var activeConnection: NWConnection?
    let port: NWEndpoint.Port

    /// Викликається при отриманні даних від PC (наприклад, кадру відео чи керуючих команд)
    var onDataReceived: ((Data) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    init(port: UInt16 = 51234) {
        self.port = NWEndpoint.Port(rawValue: port)!
    }

    func start() {
        let params = NWParameters.tcp
        params.includePeerToPeer = true // дозволяє роботу і по USB-Ethernet, і по Wi-Fi

        do {
            listener = try NWListener(using: params, on: port)
        } catch {
            print("Не вдалось створити listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Слухаємо на порту \(self.port)")
            case .failed(let error):
                print("Listener впав: \(error)")
            default:
                break
            }
        }

        listener?.start(queue: .main)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        // Приймаємо лише одне активне з'єднання за раз (одна PC-сесія)
        activeConnection?.cancel()
        activeConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.onConnected?()
                self?.receiveLoop(on: connection)
            case .failed, .cancelled:
                self?.onDisconnected?()
            default:
                break
            }
        }

        connection.start(queue: .main)
    }

    private func receiveLoop(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.onDataReceived?(data)
            }
            if isComplete || error != nil {
                connection.cancel()
                return
            }
            self?.receiveLoop(on: connection)
        }
    }

    /// Надсилає дані пера/дотику на PC (координати, тиск, нахил — серіалізовані заздалегідь)
    func send(_ data: Data) {
        activeConnection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Помилка відправки: \(error)")
            }
        })
    }

    func stop() {
        activeConnection?.cancel()
        listener?.cancel()
    }
}
