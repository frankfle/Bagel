//
//  DevicesView.swift
//  Bagel
//

import SwiftUI

struct DevicesView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedID: ObjectIdentifier?

    private var devices: [BagelDeviceController] {
        store.selectedProject?.deviceControllers ?? []
    }

    var body: some View {
        List(devices, selection: $selectedID) { device in
            VStack(alignment: .leading, spacing: 2) {
                Text(device.deviceName ?? "Unknown")
                    .font(.body)
                if let desc = device.deviceDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Device: \(device.deviceName ?? "Unknown")" +
                (device.deviceDescription.map { ", \($0)" } ?? "")
            )
            .accessibilityAddTraits(store.selectedDevice?.id == device.id ? [.isSelected] : [])
        }
        .accessibilityLabel("Devices")
        .onChange(of: selectedID) { _, newID in
            guard let id = newID,
                  let device = store.selectedProject?.deviceControllers.first(where: { $0.id == id })
            else { return }
            store.selectDevice(device)
        }
        .onReceive(store.$selectedDevice) { device in
            selectedID = device?.id
        }
    }
}
