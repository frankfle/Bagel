//
//  DetailView.swift
//  Bagel
//

import SwiftUI

enum DetailTab: String, CaseIterable, Identifiable {
    case overview         = "Overview"
    case requestHeaders   = "Request Headers"
    case requestParams    = "Request Params"
    case requestBody      = "Request Body"
    case responseHeaders  = "Response Headers"
    case responseBody     = "Response Body"

    var id: String { rawValue }

    static let requestTabs: [DetailTab] = [.overview, .requestHeaders, .requestParams, .requestBody]
    static let responseTabs: [DetailTab] = [.responseHeaders, .responseBody]
}

struct DetailView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab: DetailTab = .overview

    var body: some View {
        if let packet = store.selectedPacket {
            VStack(spacing: 0) {
                packetHeader(packet)
                Divider()
                tabBar
                Divider()
                tabContent(for: selectedTab, packet: packet)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            ContentUnavailableView(
                "Select a Request",
                systemImage: "network",
                description: Text("Choose a packet from the list to inspect its details.")
            )
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.requestTabs) { tab in
                tabButton(tab)
            }
            Spacer()
            ForEach(DetailTab.responseTabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private func tabButton(_ tab: DetailTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(tab.rawValue)
                .font(.system(.subheadline))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Detail section: \(tab.rawValue)")
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
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
