//
//  MethodPacketTableCellView.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 31.12.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class MethodPacketTableCellView: NSTableCellView {
    
    @IBOutlet private weak var titleTextField: NSTextField!
    
    var packet: BagelPacket?{
        didSet{
            guard let packet = packet else { return }
            refresh(with: packet)
        }
    }

    func refresh(with packet: BagelPacket) {
        
        var methodColor = BagelColors.httpMethodDefault

        if let requestMethod = packet.requestInfo?.requestMethod {
            switch requestMethod {
            case .get:
                methodColor = BagelColors.httpMethodGet
            case .put:
                methodColor = BagelColors.httpMethodPut
            case .post:
                methodColor = BagelColors.httpMethodPost
            case .delete:
                methodColor = BagelColors.httpMethodDelete
            case .patch:
                methodColor = BagelColors.httpMethodPatch
            case .head:
                break
            }
        }
        
        self.titleTextField.textColor = methodColor
        self.titleTextField.stringValue = packet.requestInfo?.requestMethod?.rawValue ?? ""
    }
    
}
