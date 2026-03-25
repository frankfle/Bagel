//
//  AppStore.swift
//  Bagel
//

import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    // MARK: - Published State

    @Published var projectControllers: [BagelProjectController] = []
    @Published var selectedProject: BagelProjectController?
    @Published var selectedDevice: BagelDeviceController?
    @Published var selectedPacket: BagelPacket?

    @Published var filterTerm: String = ""

    // MARK: - Derived State

    /// Filtered packet list for the current device, recomputed whenever
    /// any @Published property changes (SwiftUI re-evaluates the body).
    var filteredPackets: [BagelPacket] {
        let all = BagelController.shared.selectedProjectController?
            .selectedDeviceController?.packets ?? []
        guard !filterTerm.isEmpty else { return all }
        let term = filterTerm.lowercased()
        return all.filter { packet in
            let url = packet.requestInfo?.url?.lowercased() ?? ""
            let method = packet.requestInfo?.requestMethod?.rawValue.lowercased() ?? ""
            let status = packet.requestInfo?.statusCode?.lowercased() ?? ""
            return url.contains(term) || method.contains(term) || status.contains(term)
        }
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        let names: [NSNotification.Name] = [
            BagelNotifications.didGetPacket,
            BagelNotifications.didUpdatePacket,
            BagelNotifications.didSelectProject,
            BagelNotifications.didSelectDevice,
            BagelNotifications.didSelectPacket,
        ]
        for name in names {
            NotificationCenter.default.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.refreshFromController() }
                .store(in: &cancellables)
        }
        refreshFromController()
    }

    // MARK: - Sync from BagelController

    private func refreshFromController() {
        projectControllers = BagelController.shared.projectControllers
        selectedProject = BagelController.shared.selectedProjectController
        selectedDevice = BagelController.shared
            .selectedProjectController?.selectedDeviceController
        selectedPacket = BagelController.shared
            .selectedProjectController?.selectedDeviceController?.selectedPacket
    }

    // MARK: - Actions

    func selectProject(_ project: BagelProjectController) {
        BagelController.shared.selectedProjectController = project
    }

    func selectDevice(_ device: BagelDeviceController) {
        BagelController.shared.selectedProjectController?.selectedDeviceController = device
    }

    func selectPacket(_ packet: BagelPacket?) {
        BagelController.shared.selectedProjectController?
            .selectedDeviceController?.select(packet: packet)
    }

    func clearPackets() {
        BagelController.shared.selectedProjectController?.selectedDeviceController?.clear()
        refreshFromController()
    }
}
