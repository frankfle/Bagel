//
//  ContentBottomBar.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 6.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class ContentBar: NSBox {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setThemeColor()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setThemeColor()
    }

    func setThemeColor() {
        self.fillColor = BagelColors.contentBar
    }
}
