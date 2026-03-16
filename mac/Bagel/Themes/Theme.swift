//
//  Theme.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 7.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import AppKit

enum BagelColors {

    static var controlBackground: NSColor { NSColor(named: "controlBackground")! }
    static var labelColor: NSColor { NSColor(named: "labelColor")! }
    static var secondaryLabel: NSColor { NSColor(named: "secondaryLabel")! }
    static var contentBar: NSColor { NSColor(named: "contentBar")! }
    static var gridColor: NSColor { NSColor(named: "gridColor")! }
    static var separator: NSColor { NSColor(named: "separator")! }
    static var rowSelected: NSColor { NSColor(named: "rowSelected")! }

    static var statusGreen: NSColor { NSColor(named: "statusGreen")! }
    static var statusOrange: NSColor { NSColor(named: "statusOrange")! }
    static var statusRed: NSColor { NSColor(named: "statusRed")! }

    static var projectListBackground: NSColor { NSColor(named: "projectListBackground")! }
    static var projectText: NSColor { NSColor(named: "projectText")! }
    static var deviceListBackground: NSColor { NSColor(named: "deviceListBackground")! }
    static var deviceRowSelected: NSColor { NSColor(named: "deviceRowSelected")! }
    static var packetListAndDetailBackground: NSColor { NSColor(named: "packetListAndDetailBackground")! }

    static var httpMethodGet: NSColor { NSColor(named: "httpMethodGet")! }
    static var httpMethodPost: NSColor { NSColor(named: "httpMethodPost")! }
    static var httpMethodDelete: NSColor { NSColor(named: "httpMethodDelete")! }
    static var httpMethodPut: NSColor { NSColor(named: "httpMethodPut")! }
    static var httpMethodPatch: NSColor { NSColor(named: "httpMethodPatch")! }
    static var httpMethodDefault: NSColor { NSColor(named: "httpMethodDefault")! }
}

enum BagelImages {

    static var clearIcon: NSImage { NSImage(named: "TrashIcon")! }
    static var copyToClipboardIcon: NSImage { NSImage(named: "CopyIcon")! }
}
