//
//  PacketsView.swift
//  Bagel
//

import SwiftUI

struct PacketsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedID: String?
    @State private var isAtBottom = true
    @State private var lastAnnouncementCount = 0
    @State private var sortOrder: [KeyPathComparator<BagelPacket>] = []

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            Divider()
            packetTable
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.clearPackets()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .accessibilityLabel("Clear packets")
                .accessibilityHint("Removes all captured packets for the current device")
                .help("Clear all packets")
            }
        }
        .onChange(of: store.filteredPackets.count) { _, newCount in
            announceNewPacketsIfNeeded(count: newCount)
        }
        .onReceive(store.$selectedPacket) { packet in
            selectedID = packet?.id
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter by URL, method, or status", text: $store.filterTerm)
                .textFieldStyle(.plain)
                .accessibilityLabel("Filter packets")
                .accessibilityHint("Filter by URL, method, or status code")
            if !store.filterTerm.isEmpty {
                Button {
                    store.filterTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear filter")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Packet Table

    private var sortedPackets: [BagelPacket] {
        store.filteredPackets.sorted(using: sortOrder)
    }

    private var packetTable: some View {
        ScrollViewReader { proxy in
            Table(sortedPackets, selection: Binding(
                get: { selectedID },
                set: { newID in
                    selectedID = newID
                    if let id = newID,
                       let packet = store.filteredPackets.first(where: { $0.id == id }) {
                        store.selectPacket(packet)
                    }
                }
            ), sortOrder: $sortOrder) {
                TableColumn("Status", value: \.statusDisplayValue) { packet in
                    Text(packet.statusDisplayValue)
                        .foregroundStyle(packet.statusColor)
                        .monospacedDigit()
                }
                .width(60)

                TableColumn("Method", value: \.methodDisplayValue) { packet in
                    Text(packet.methodDisplayValue)
                        .foregroundStyle(packet.methodColor)
                }
                .width(52)

                TableColumn("URL", value: \.urlDisplayValue) { packet in
                    Text(packet.urlDisplayValue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                TableColumn("Duration", value: \.durationSortValue) { packet in
                    Text(packet.durationDisplayValue)
                        .foregroundStyle(packet.durationColor)
                        .monospacedDigit()
                }
                .width(60)

                TableColumn("Date", value: \.dateSortValue) { packet in
                    Text(packet.requestInfo?.startDate?.readable ?? "")
                        .foregroundStyle(.secondary)
                }
                .width(160)
            }
            .accessibilityLabel("Network packets")
            .onChange(of: store.filteredPackets.count) { _, _ in
                if isAtBottom, let last = store.filteredPackets.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            // Track scroll position via background GeometryReader sentinel
            .background(alignment: .bottom) {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { _, minY in
                            let newValue: Bool
                            if let screenHeight = NSScreen.main?.visibleFrame.height {
                                newValue = minY < screenHeight
                            } else {
                                newValue = true
                            }
                            if newValue != isAtBottom {
                                isAtBottom = newValue
                            }
                        }
                }
                .frame(height: 1)
            }
        }
    }

    // MARK: - Accessibility

    private func announceNewPacketsIfNeeded(count: Int) {
        guard count > lastAnnouncementCount else { return }
        lastAnnouncementCount = count
        NSAccessibility.post(
            element: NSApp.mainWindow as Any,
            notification: .announcementRequested,
            userInfo: [
                NSAccessibility.NotificationUserInfoKey.announcement: "New network request captured" as NSString,
                NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.low.rawValue,
            ]
        )
    }
}

// MARK: - BagelPacket display helpers

extension BagelPacket {

    var statusDisplayValue: String {
        if let code = requestInfo?.statusCode, !code.isEmpty {
            return code
        }
        if let errorCode = requestInfo?.errorCode {
            return shortErrorLabel(domain: requestInfo?.errorDomain, code: errorCode).uppercased()
        }
        return ""
    }

    var methodDisplayValue: String { requestInfo?.requestMethod?.rawValue ?? "" }
    var urlDisplayValue: String    { requestInfo?.url ?? "" }

    /// Sortable duration string (zero-padded for lexicographic sort)
    var durationSortValue: String {
        guard let start = requestInfo?.startDate,
              let end = requestInfo?.endDate else { return "" }
        let d = end.timeIntervalSince(start)
        return String(format: "%020.6f", d)
    }

    /// Sortable date string
    var dateSortValue: String {
        requestInfo?.startDate?.readable ?? ""
    }

    var statusColor: Color {
        if let code = requestInfo?.statusCode, let codeInt = Int(code) {
            if codeInt >= 200 && codeInt < 300 { return Color("statusGreen") }
            if codeInt >= 300 && codeInt < 400 { return Color("statusOrange") }
            if codeInt >= 400 { return Color("statusRed") }
        }
        if requestInfo?.errorCode != nil { return Color("statusRed") }
        return .primary
    }

    var methodColor: Color {
        switch requestInfo?.requestMethod {
        case .get:    return Color("httpMethodGet")
        case .post:   return Color("httpMethodPost")
        case .put:    return Color("httpMethodPut")
        case .delete: return Color("httpMethodDelete")
        case .patch:  return Color("httpMethodPatch")
        default:      return Color("httpMethodDefault")
        }
    }

    var durationDisplayValue: String {
        guard let start = requestInfo?.startDate,
              let end = requestInfo?.endDate else { return "" }
        return Self.formattedDuration(end.timeIntervalSince(start))
    }

    var durationColor: Color {
        guard let start = requestInfo?.startDate,
              let end = requestInfo?.endDate else { return .secondary }
        let d = end.timeIntervalSince(start)
        if d < 0.5 { return Color("statusGreen") }
        if d < 2.0 { return Color("statusOrange") }
        return Color("statusRed")
    }

    static func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 0 { return "" }
        if duration < 1.0 { return String(format: "%.0f ms", duration * 1000) }
        if duration < 60.0 { return String(format: "%.2f s", duration) }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }

    private func shortErrorLabel(domain: String?, code: Int) -> String {
        if domain == "NSURLErrorDomain" || domain == "kCFErrorDomainCFNetwork" {
            switch code {
            case -1001: return "Timeout"
            case -1003: return "DNS"
            case -1004: return "Refused"
            case -1005: return "Lost"
            case -1009: return "Offline"
            case -1200: return "SSL"
            case -1202: return "SSL Trust"
            case -999:  return "Cancelled"
            case -1011: return "Bad Reply"
            case -1002: return "Bad URL"
            default:    return "\(code)"
            }
        }
        return "\(code)"
    }
}
