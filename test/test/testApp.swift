//
//  testApp.swift
//  test
//
//  Created by Frank Fleschner on 3/17/26.
//

import SwiftUI
import Bagel

@main
struct testApp: App {

    init() {
        Bagel.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
