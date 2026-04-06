import SwiftUI

struct WeatherResponse: Decodable {
    let currentWeather: CurrentWeather

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
    }
}

struct CurrentWeather: Decodable {
    let temperature: Double
    let windspeed: Double
}

struct ContentView: View {
    @State private var status = "Ready"
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Bagel macOS Test")
                .font(.title)

            Text(status)
                .font(.body)
                .monospaced()
                .foregroundStyle(statusColor)

            Button("Fetch Weather") {
                fetchWeather()
            }
            .disabled(isLoading)
        }
        .padding(40)
        .frame(minWidth: 300, minHeight: 200)
    }

    private var statusColor: Color {
        if status.hasPrefix("Error") { return .red }
        if status.hasPrefix("KC") { return .green }
        return .secondary
    }

    private func fetchWeather() {
        isLoading = true
        status = "Loading..."

        Task {
            do {
                let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=39.10&longitude=-94.58&current_weather=true")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                status = "KC: \(weather.currentWeather.temperature)°C, wind \(weather.currentWeather.windspeed) km/h"
            } catch {
                status = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
