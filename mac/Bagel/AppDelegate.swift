//
//  AppDelegate.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 30/07/2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var isAppActive = true
    private var backgroundPacketCount = 0
    private var packetObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for window in NSApplication.shared.windows {
            window.standardWindowButton(.closeButton)?.isEnabled = false
        }
        packetObserver = NotificationCenter.default.addObserver(
            forName: BagelNotifications.didGetPacket,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if !self.isAppActive {
                self.backgroundPacketCount += 1
                NSApplication.shared.dockTile.badgeLabel = String(self.backgroundPacketCount)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        isAppActive = true
        NSApplication.shared.dockTile.badgeLabel = ""
        backgroundPacketCount = 0
    }

    func applicationWillResignActive(_ notification: Notification) {
        isAppActive = false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {

        for window in sender.windows {
            window.orderFront(self)
        }

        return true
    }
}
