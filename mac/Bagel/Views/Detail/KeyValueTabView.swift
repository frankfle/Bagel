//
//  KeyValueTabView.swift
//  Bagel
//

import SwiftUI

struct KeyValueTabView: View {
    let keyValues: [KeyValue]
    let label: String
    @State private var isRaw = false

    private var rawString: String {
        keyValues.map { "\($0.key ?? ""): \($0.value ?? "")" }.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack {
                Toggle("Raw", isOn: $isRaw)
                    .toggleStyle(.button)
                    .accessibilityLabel("Toggle raw text")
                    .accessibilityHint("Show \(label) as plain text")
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(rawString, forType: .string)
                }
                .accessibilityLabel("Copy \(label) to clipboard")
            }
            .padding([.top, .trailing], 8)

            if isRaw {
                ScrollView {
                    Text(rawString)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)
                }
                .accessibilityLabel("\(label) plain text")
            } else if keyValues.isEmpty {
                ContentUnavailableView("No \(label)", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(keyValues) {
                    TableColumn("Key") { kv in
                        Text(kv.key ?? "")
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 80, ideal: 160)
                    TableColumn("Value") { kv in
                        Text(kv.value ?? "")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .accessibilityLabel("\(label) table")
            }
        }
    }
}
