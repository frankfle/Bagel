//
//  HighlightrTextView.swift
//  Bagel
//

import SwiftUI
import Highlightr

struct HighlightrTextView: NSViewRepresentable {
    let jsonString: String
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let contentSize = scrollView.contentSize
        let textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.setAccessibilityLabel("JSON body")

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.highlightr = Highlightr()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        let isDark = colorScheme == .dark
        coordinator.highlightr?.setTheme(to: isDark ? "paraiso-dark" : "github")

        guard coordinator.lastJSON != jsonString else { return }
        coordinator.lastJSON = jsonString
        coordinator.textView?.string = ""

        guard !jsonString.isEmpty else { return }

        let capturedHighlightr = coordinator.highlightr
        let capturedTextView = coordinator.textView

        DispatchQueue.global(qos: .userInitiated).async {
            let result = capturedHighlightr?.highlight(jsonString, as: "json")
            DispatchQueue.main.async {
                if let highlighted = result {
                    capturedTextView?.textStorage?.setAttributedString(highlighted)
                } else {
                    capturedTextView?.string = jsonString
                }
            }
        }
    }

    final class Coordinator {
        var highlightr: Highlightr?
        var textView: NSTextView?
        var lastJSON = ""
    }
}
