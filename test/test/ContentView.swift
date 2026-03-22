//
//  ContentView.swift
//  test
//
//  Created by Frank Fleschner on 3/17/26.
//

import SwiftUI

struct ContentView: View {
    @State private var status = "Idle"
    @State private var detail = ""
    @State private var isLoading = false

    private let service = NetworkTestService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Status banner
                    VStack(spacing: 4) {
                        Text(status)
                            .foregroundStyle(statusColor)
                            .font(.headline)

                        if !detail.isEmpty {
                            Text(detail)
                                .font(.caption)
                                .monospaced()
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // URLSession Data Tasks
                    testSection("URLSession Data Tasks") {
                        testButton("GET (simple)", systemImage: "arrow.down.circle") {
                            try await service.simpleGet()
                        }
                        testButton("GET (custom headers)", systemImage: "list.bullet.rectangle") {
                            try await service.getWithHeaders()
                        }
                        testButton("POST (JSON body)", systemImage: "arrow.up.circle") {
                            try await service.postJSON()
                        }
                    }

                    // Other Task Types
                    testSection("Other Task Types") {
                        testButton("Download Task", systemImage: "arrow.down.doc") {
                            try await service.downloadFile()
                        }
                        testButton("Upload Task", systemImage: "arrow.up.doc") {
                            try await service.uploadData()
                        }
                    }

                    // Session Configurations
                    testSection("Session Configurations") {
                        testButton("Ephemeral Session", systemImage: "lock.shield") {
                            try await service.ephemeralSessionGet()
                        }
                    }

                    // Legacy API
                    testSection("Legacy (NSURLConnection)") {
                        legacyTestButton()
                    }

                    // Error Scenarios
                    testSection("Error Scenarios") {
                        testButton("Bad Request (400)", systemImage: "xmark.circle") {
                            try await service.errorBadRequest()
                        }
                        testButton("Timeout", systemImage: "clock.badge.xmark") {
                            try await service.errorTimeout()
                        }
                        testButton("Bad Host (DNS)", systemImage: "wifi.slash") {
                            try await service.errorBadHost()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Bagel Test")
        }
    }

    private var statusColor: Color {
        switch status {
        case "Success": .green
        case _ where status.hasPrefix("Error"): .red
        default: .secondary
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func testSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Test Buttons

    private func testButton(_ label: String, systemImage: String, action: @escaping () async throws -> String) -> some View {
        Button {
            runTest(action)
        } label: {
            Label(label, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(isLoading)
    }

    private func legacyTestButton() -> some View {
        Button {
            runLegacyTest()
        } label: {
            Label("NSURLConnection GET", systemImage: "clock.arrow.circlepath")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(isLoading)
    }

    // MARK: - Test Runners

    private func runTest(_ block: @escaping () async throws -> String) {
        isLoading = true
        status = "Loading..."
        detail = ""

        Task {
            do {
                let result = try await block()
                status = "Success"
                detail = result
            } catch {
                status = "Error"
                detail = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func runLegacyTest() {
        isLoading = true
        status = "Loading..."
        detail = ""

        service.legacyConnectionGet { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    status = "Success"
                    detail = message
                case .failure(let error):
                    status = "Error"
                    detail = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
