//
//  WeatherService.swift
//  test
//
//  Created by Claude on 3/17/26.
//

import Foundation

struct WeatherResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let currentWeather: CurrentWeather

    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case currentWeather = "current_weather"
    }
}

struct CurrentWeather: Decodable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
}

enum WeatherError: LocalizedError {
    case badResponse(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "HTTP \(code)"
        case .decodingFailed: return "Failed to decode response"
        }
    }
}

struct WeatherService {

    func fetchCurrentWeather() async throws -> WeatherResponse {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current_weather=true")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WeatherError.badResponse(code)
        }

        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }

    func fetchInvalidRequest() async throws -> Data {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=INVALID")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WeatherError.badResponse(code)
        }

        return data
    }
}
