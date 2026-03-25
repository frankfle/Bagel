//
//  DetailView.swift
//  Bagel
//

import SwiftUI

enum DetailTab: String, CaseIterable, Identifiable {
    case overview         = "Overview"
    case requestHeaders   = "Req Headers"
    case requestParams    = "Req Params"
    case requestBody      = "Req Body"
    case responseHeaders  = "Res Headers"
    case responseBody     = "Res Body"

    var id: String { rawValue }
}

struct DetailView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab: DetailTab = .overview

    var body: some View {
        if let packet = store.selectedPacket {
            VStack(spacing: 0) {
                packetHeader(packet)
                Divider()
                TabView(selection: $selectedTab) {
                    ForEach(DetailTab.allCases) { tab in
                        tabContent(for: tab, packet: packet)
                            .tabItem { Text(tab.rawValue) }
                            .tag(tab)
                            .accessibilityLabel("Detail section: \(tab.rawValue)")
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Select a Request",
                systemImage: "network",
                description: Text("Choose a packet from the list to inspect its details.")
            )
        }
    }

    // MARK: - Header

    private func packetHeader(_ packet: BagelPacket) -> some View {
        HStack(spacing: 8) {
            if let method = packet.requestInfo?.requestMethod?.rawValue {
                Text(method)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(packet.methodColor)
            }
            Text(packet.requestInfo?.url ?? "")
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(packet.requestInfo?.requestMethod?.rawValue ?? "") \(packet.requestInfo?.url ?? "")"
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: DetailTab, packet: BagelPacket) -> some View {
        switch tab {
        case .overview:
            OverviewTabView(packet: packet)

        case .requestHeaders:
            KeyValueTabView(
                keyValues: packet.requestInfo?.requestHeaders?.toKeyValueArray() ?? [],
                label: "Request Headers"
            )

        case .requestParams:
            let params: [KeyValue] = {
                guard let urlStr = packet.requestInfo?.url,
                      let url = URL(string: urlStr) else { return [] }
                return url.toKeyValueArray()
            }()
            KeyValueTabView(keyValues: params, label: "Request Parameters")

        case .requestBody:
            DataTabView(
                data: packet.requestInfo?.requestBody?.base64Data,
                label: "Request Body"
            )

        case .responseHeaders:
            KeyValueTabView(
                keyValues: packet.requestInfo?.responseHeaders?.toKeyValueArray() ?? [],
                label: "Response Headers"
            )

        case .responseBody:
            DataTabView(
                data: packet.requestInfo?.responseData?.base64Data,
                label: "Response Body"
            )
        }
    }
}
