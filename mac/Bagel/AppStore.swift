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

    @Published var addressFilterTerm: String = ""
    @Published var methodFilterTerm: String = ""
    @Published var statusFilterTerm: String = ""

    // MARK: - Derived State

    /// Filtered packet list for the current device, recomputed whenever
    /// any @Published property changes (SwiftUI re-evaluates the body).
    var filteredPackets: [BagelPacket] {
        let all = BagelController.shared.selectedProjectController?
            .selectedDeviceController?.packets ?? []
        return performStatusFiltration(
            performMethodFiltration(
                performAddressFiltration(all)
            )
        )
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

    // MARK: - Filtering (ported verbatim from PacketsViewModel)

    private func performAddressFiltration(_ items: [BagelPacket]) -> [BagelPacket] {
        guard !addressFilterTerm.isEmpty else { return items }
        return items.filter { $0.requestInfo?.url?.contains(addressFilterTerm) ?? true }
    }

    private func performMethodFiltration(_ items: [BagelPacket]) -> [BagelPacket] {
        guard !methodFilterTerm.isEmpty else { return items }
        return items.filter {
            $0.requestInfo?.requestMethod?.rawValue.lowercased()
                .contains(methodFilterTerm.lowercased()) ?? true
        }
    }

    private func performStatusFiltration(_ items: [BagelPacket]) -> [BagelPacket] {
        guard !statusFilterTerm.isEmpty else { return items }
        guard !statusFilterTerm.trimmingCharacters(in: .whitespaces).isEmpty else {
            return items.filter {
                $0.requestInfo?.statusCode?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
            }
        }
        return items.filter { $0.requestInfo?.statusCode?.contains(statusFilterTerm) ?? false }
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
