//
//  CSVExporter.swift
//  Bagel
//

import Foundation

enum CSVExporter {

    private static let columns = [
        "Method", "URL", "Status", "Duration",
        "Start Date", "End Date",
        "Request Headers", "Request Body",
        "Response Headers", "Response Body",
        "Error",
    ]

    static func export(_ packets: [BagelPacket]) -> String {
        var rows: [String] = []
        rows.append(columns.map { escapeField($0) }.joined(separator: ","))

        for packet in packets {
            let info = packet.requestInfo
            let row = [
                info?.requestMethod?.rawValue ?? "",
                info?.url ?? "",
                info?.statusCode ?? "",
                durationString(start: info?.startDate, end: info?.endDate),
                info?.startDate?.readable ?? "",
                info?.endDate?.readable ?? "",
                headersString(info?.requestHeaders),
                bodyString(info?.requestBody),
                headersString(info?.responseHeaders),
                bodyString(info?.responseData),
                errorString(info),
            ]
            rows.append(row.map { escapeField($0) }.joined(separator: ","))
        }

        return rows.joined(separator: "\r\n")
    }

    // MARK: - Field Helpers

    private static func durationString(start: Date?, end: Date?) -> String {
        guard let start, let end else { return "" }
        return BagelPacket.formattedDuration(end.timeIntervalSince(start))
    }

    private static func headersString(_ headers: [String: String]?) -> String {
        guard let headers, !headers.isEmpty else { return "" }
        return headers.sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }

    private static func bodyString(_ base64Body: String?) -> String {
        guard let base64Body,
              let data = base64Body.base64Data else { return "" }
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        return "<binary data>"
    }

    private static func errorString(_ info: BagelRequestInfo?) -> String {
        guard let code = info?.errorCode else { return "" }
        var parts: [String] = []
        if let domain = info?.errorDomain { parts.append(domain) }
        parts.append("code \(code)")
        if let desc = info?.errorDescription { parts.append(desc) }
        return parts.joined(separator: " — ")
    }

    // MARK: - RFC 4180 Escaping

    private static func escapeField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
