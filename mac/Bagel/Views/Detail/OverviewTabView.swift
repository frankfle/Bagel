//
//  OverviewTabView.swift
//  Bagel
//

import SwiftUI

struct OverviewTabView: View {
    let packet: BagelPacket
    @State private var isCurl = false

    private var overviewText: String {
        ContentRepresentationParser.overviewRepresentation(
            requestInfo: packet.requestInfo ?? BagelRequestInfo()
        ).rawString ?? ""
    }

    private var curlText: String {
        CURLRepresentation(requestInfo: packet.requestInfo).rawString ?? ""
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack {
                Toggle("cURL", isOn: $isCurl)
                    .toggleStyle(.button)
                    .accessibilityLabel("Toggle cURL view")
                    .accessibilityHint("Show cURL command for this request")
                Button("Copy") {
                    let text = isCurl ? curlText : overviewText
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                .accessibilityLabel("Copy to clipboard")
            }
            .padding([.top, .trailing], 8)

            ScrollView {
                Text(isCurl ? curlText : overviewText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .accessibilityLabel(isCurl ? "cURL command" : "Request overview")
        }
    }
}
