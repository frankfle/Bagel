//
//  DataJSONViewController.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 2.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import WebKit
import Highlightr

class DataJSONViewController: BaseViewController {

    var viewModel: DataJSONViewModel?

    let highlightr = Highlightr()

    @IBOutlet var rawTextView: NSTextView!

    @IBOutlet weak var rawTextScrollView: NSScrollView!
    @IBOutlet weak var copyToClipboardButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    override func setup() {

        self.copyToClipboardButton.image = BagelImages.copyToClipboardIcon

        self.viewModel?.onChange = { [weak self] in
            self?.refresh()
        }

        self.refresh()
        self.refreshHighlightrTheme()
    }

    func refresh() {
        self.rawTextView.string = ""
        if let jsonString = self.viewModel?.dataRepresentation?.rawString {
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
            DispatchQueue.global(qos: .background).async {
                if let highlightedCode = self.highlightr?.highlight(jsonString, as: "json") {
                    DispatchQueue.main.async {
                        self.rawTextView.textStorage?.setAttributedString(highlightedCode)
                        self.progressIndicator.isHidden = true
                        self.progressIndicator.stopAnimation(nil)
                    }
                }
            }
        }
    }

    func refreshHighlightrTheme() {
        let isDark = self.view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        self.highlightr?.setTheme(to: isDark ? "paraiso-dark" : "github")
    }

//    override func viewDidChangeEffectiveAppearance() {
//        super.viewDidChangeEffectiveAppearance()
//        self.refreshHighlightrTheme()
//        self.refresh()
//    }

    @IBAction func copyButtonAction(_ sender: Any) {
        self.viewModel?.copyToClipboard()
    }
}
