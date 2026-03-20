//
//  StatusPacketTableCellView.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 1.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class StatusPacketTableCellView: NSTableCellView {

    @IBOutlet weak var titleTextField: NSTextField!
    
    var packet: BagelPacket!
    {
        didSet
        {
            self.refresh()
        }
    }
    
    func refresh() {

        var titleTextColor = NSColor.black
        var displayValue = ""

        if let statusCode = self.packet.requestInfo?.statusCode, let statusCodeInt = Int(statusCode) {

            displayValue = statusCode

            if statusCodeInt >= 200 && statusCodeInt < 300 {
                titleTextColor = BagelColors.statusGreen
            } else if statusCodeInt >= 300 && statusCodeInt < 400 {
                titleTextColor = BagelColors.statusOrange
            } else if statusCodeInt >= 400 {
                titleTextColor = BagelColors.statusRed
            }

        } else if self.packet.requestInfo?.errorCode != nil {
            displayValue = self.shortErrorLabel(
                domain: self.packet.requestInfo?.errorDomain,
                code: self.packet.requestInfo?.errorCode
            ).uppercased()
            titleTextColor = BagelColors.statusRed
        }

        self.titleTextField.textColor = titleTextColor
        self.titleTextField.stringValue = displayValue
    }

    private func shortErrorLabel(domain: String?, code: Int?) -> String {
        guard let code = code else { return "Error" }

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
