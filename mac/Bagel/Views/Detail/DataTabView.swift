//
//  DataTabView.swift
//  Bagel
//

import SwiftUI

struct DataTabView: View {
    let data: Data?
    let label: String

    private var representation: DataRepresentation? {
        guard let data else { return nil }
        return ContentRepresentationParser.dataRepresentation(data: data)
    }

    var body: some View {
        if let rep = representation {
            switch rep.type {
            case .json:
                jsonView(rawString: rep.rawString ?? "")
            case .image:
                imageView(rep: rep)
            case .text:
                textView(rawString: rep.rawString ?? "")
            case .none:
                emptyView
            }
        } else {
            emptyView
        }
    }

    // MARK: - Sub-views

    private func jsonView(rawString: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            copyButton(text: rawString)
                .padding([.top, .trailing], 8)
            HighlightrTextView(jsonString: rawString)
                .accessibilityLabel("\(label) JSON")
        }
    }

    private func textView(rawString: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            copyButton(text: rawString)
                .padding([.top, .trailing], 8)
            ScrollView {
                Text(rawString)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .accessibilityLabel("\(label) text")
        }
    }

    private func imageView(rep: DataRepresentation) -> some View {
        ScrollView([.horizontal, .vertical]) {
            if let imgData = rep.originalData, let image = NSImage(data: imgData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .accessibilityLabel("\(label) image")
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView("No \(label)", systemImage: "doc.text")
    }

    private func copyButton(text: String) -> some View {
        Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
        .accessibilityLabel("Copy \(label) to clipboard")
    }
}
