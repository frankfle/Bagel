//
//  DurationPacketTableCellView.swift
//  Bagel
//
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class DurationPacketTableCellView: NSTableCellView {

    @IBOutlet private weak var titleTextField: NSTextField!

    var packet: BagelPacket? {
        didSet {
            guard let packet = packet else { return }
            refresh(with: packet)
        }
    }

    func refresh(with packet: BagelPacket) {
        guard let startDate = packet.requestInfo?.startDate,
              let endDate = packet.requestInfo?.endDate else {
            titleTextField.textColor = BagelColors.secondaryLabel
            titleTextField.stringValue = ""
            return
        }

        let duration = endDate.timeIntervalSince(startDate)
        titleTextField.stringValue = Self.formattedDuration(duration)

        if duration < 0.5 {
            titleTextField.textColor = BagelColors.statusGreen
        } else if duration < 2.0 {
            titleTextField.textColor = BagelColors.statusOrange
        } else {
            titleTextField.textColor = BagelColors.statusRed
        }
    }

    static func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 0 {
            return ""
        } else if duration < 1.0 {
            // Show as milliseconds: "342 ms"
            let ms = duration * 1000
            return String(format: "%.0f ms", ms)
        } else if duration < 60.0 {
            // Show as seconds: "1.23 s"
            return String(format: "%.2f s", duration)
        } else {
            // Show as minutes and seconds: "2m 15s"
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}
