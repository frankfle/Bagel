//
//  NetworkTestService.swift
//  test
//
//  Created by Claude on 3/18/26.
//

import Foundation

// MARK: - Response Models

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

struct JsonPlaceholderPost: Codable {
    let id: Int?
    let title: String
    let body: String
    let userId: Int
}

// MARK: - Errors

enum NetworkTestError: LocalizedError {
    case badResponse(Int)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "HTTP \(code)"
        case .invalidURL: return "Invalid URL"
        }
    }
}

// MARK: - NSURLConnection Delegate Helper

class LegacyConnectionDelegate: NSObject, NSURLConnectionDataDelegate {
    var receivedData = Data()
    var response: URLResponse?
    var completion: ((Result<(Data, URLResponse?), Error>) -> Void)?

    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.response = response
        receivedData = Data()
    }

    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        receivedData.append(data)
    }

    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        completion?(.success((receivedData, response)))
    }

    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        completion?(.failure(error))
    }
}

// MARK: - NetworkTestService

struct NetworkTestService {

    // MARK: Test 1 - Simple GET (URLSession data task)

    func simpleGet() async throws -> String {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=39.10&longitude=-94.58&current_weather=true")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return "Kansas City: \(weather.currentWeather.temperature)°C, wind \(weather.currentWeather.windspeed) km/h"
    }

    // MARK: Test 2 - GET with custom headers

    func getWithHeaders() async throws -> String {
        var request = URLRequest(url: URL(string: "https://httpbin.org/headers")!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BagelTestApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("bagel-test-value", forHTTPHeaderField: "X-Custom-Header")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let headers = json?["headers"] as? [String: Any] ?? [:]
        let customHeader = headers["X-Custom-Header"] as? String ?? "not found"
        return "Custom header echoed: \(customHeader)"
    }

    // MARK: Test 3 - POST with JSON body

    func postJSON() async throws -> String {
        var request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let post = JsonPlaceholderPost(id: nil, title: "Bagel Test", body: "Testing POST request", userId: 1)
        request.httpBody = try JSONEncoder().encode(post)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        let created = try JSONDecoder().decode(JsonPlaceholderPost.self, from: data)
        return "Created post with id: \(created.id ?? -1)"
    }

    // MARK: Test 4 - Download task

    func downloadFile() async throws -> String {
        let url = URL(string: "https://httpbin.org/image/png")!
        let (fileURL, response) = try await URLSession.shared.download(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let size = attributes[.size] as? Int64 ?? 0
        return "Downloaded \(size) bytes to temp file"
    }

    // MARK: Test 5 - Upload task

    func uploadData() async throws -> String {
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyData = try JSONEncoder().encode(["message": "Bagel upload test", "timestamp": "\(Date())"])

        let (data, response) = try await URLSession.shared.upload(for: request, from: bodyData)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        return "Upload complete, response: \(data.count) bytes"
    }

    // MARK: Test 6 - Ephemeral session

    func ephemeralSessionGet() async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        let url = URL(string: "https://httpbin.org/get")!
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        return "Ephemeral session response: \(data.count) bytes"
    }

    // MARK: Test 7 - NSURLConnection (legacy)

    func legacyConnectionGet(completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://httpbin.org/get")!
        let request = URLRequest(url: url)

        let delegate = LegacyConnectionDelegate()
        delegate.completion = { result in
            switch result {
            case .success(let (data, response)):
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.success("NSURLConnection response: HTTP \(code), \(data.count) bytes"))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        let connection = NSURLConnection(request: request, delegate: delegate)
        connection?.start()
    }

    // MARK: Test 8 - Bad request (HTTP error)

    func errorBadRequest() async throws -> String {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=INVALID")!
        let (_, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        return "Unexpected success"
    }

    // MARK: Test 9 - Timeout

    func errorTimeout() async throws -> String {
        var request = URLRequest(url: URL(string: "https://httpbin.org/delay/10")!)
        request.timeoutInterval = 1.0

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        return "Unexpected success"
    }

    // MARK: Test 10 - Bad host (DNS failure)

    func errorBadHost() async throws -> String {
        let url = URL(string: "https://this-domain-does-not-exist-bagel-test.invalid/api")!
        let (_, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkTestError.badResponse(code)
        }

        return "Unexpected success"
    }
}
