//
//  BagelPublisher.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 26.09.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import Network

protocol BagelPublisherDelegate {

    func didGetPacket(publisher: BagelPublisher, packet: BagelPacket)
}

class BagelPublisher: NSObject {

    var delegate: BagelPublisherDelegate?

    var listener: NWListener?
    var connections: [NWConnection] = []

    func startPublishing() {

        // Cancel any existing listener before creating a new one
        if let existingListener = self.listener {
            existingListener.stateUpdateHandler = nil
            existingListener.newConnectionHandler = nil
            existingListener.cancel()
            self.listener = nil
        }

        self.connections = []

        do {
            let parameters = NWParameters.tcp
            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(BagelConfiguration.netServicePort)))
        } catch {
            self.tryPublishAgain()
            return
        }

        guard let listener = self.listener else { return }

        listener.service = NWListener.Service(
            name: BagelConfiguration.netServiceName.isEmpty ? nil : BagelConfiguration.netServiceName,
            type: BagelConfiguration.netServiceType
        )

        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("publish ready on port \(listener.port?.rawValue ?? 0)")
            case .failed(let error):
                print("listener failed: \(error)")
                self?.listener?.cancel()
                self?.tryPublishAgain()
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener.start(queue: DispatchQueue.global(qos: .background))
    }

    private func handleNewConnection(_ connection: NWConnection) {

        self.connections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed(_), .cancelled:
                self?.removeConnection(connection)
            default:
                break
            }
        }

        connection.start(queue: DispatchQueue.global(qos: .background))
        readHeader(from: connection)
    }

    private func readHeader(from connection: NWConnection) {

        let headerLength = MemoryLayout<UInt64>.stride

        connection.receive(minimumIncompleteLength: headerLength, maximumLength: headerLength) { [weak self] data, _, isComplete, error in

            if let data = data, data.count == headerLength {
                let bodyLength = self?.lengthOf(data: data) ?? 0
                self?.readBody(from: connection, length: bodyLength)
            } else if isComplete || error != nil {
                self?.removeConnection(connection)
            }
        }
    }

    private func readBody(from connection: NWConnection, length: Int) {

        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in

            if let data = data, data.count == length {
                self?.parseBody(data: data)
                self?.readHeader(from: connection)
            } else if isComplete || error != nil {
                self?.removeConnection(connection)
            }
        }
    }

    private func removeConnection(_ connection: NWConnection) {

        // Guard against double-removal of the same connection
        guard self.connections.contains(where: { $0 === connection }) else { return }

        connection.cancel()
        self.connections.removeAll { $0 === connection }
    }

    func lengthOf(data: Data) -> Int {

        var length: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &length) { data.copyBytes(to: $0) }
        return Int(length)
    }

    func parseBody(data: Data) {

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        do {

            let bagelPacket = try jsonDecoder.decode(BagelPacket.self, from: data)

            DispatchQueue.main.async {
                self.delegate?.didGetPacket(publisher: self, packet: bagelPacket)
            }

        } catch {

            print(error)
        }
    }

    func tryPublishAgain() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

            self.startPublishing()

        }

    }
}
