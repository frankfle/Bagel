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

    private let service = WeatherService()

    var body: some View {
        VStack(spacing: 20) {
            Text("Bagel Test")
                .font(.title)

            Text(status)
                .foregroundStyle(statusColor)
                .font(.headline)

            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .monospaced()
                    .padding(8)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            Button("Fetch Weather") {
                fetchWeather()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button("Fetch Invalid Request") {
                fetchInvalid()
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
        }
        .padding()
    }

    private var statusColor: Color {
        switch status {
        case "Success": .green
        case _ where status.hasPrefix("Error"): .red
        default: .secondary
        }
    }

    private func fetchWeather() {
        isLoading = true
        status = "Loading..."
        detail = ""

        Task {
            do {
                let weather = try await service.fetchCurrentWeather()
                status = "Success"
                detail = "Berlin: \(weather.currentWeather.temperature)°C, wind \(weather.currentWeather.windspeed) km/h"
            } catch {
                status = "Error"
                detail = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func fetchInvalid() {
        isLoading = true
        status = "Loading..."
        detail = ""

        Task {
            do {
                _ = try await service.fetchInvalidRequest()
                status = "Success"
                detail = "Unexpected success"
            } catch {
                status = "Error"
                detail = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
