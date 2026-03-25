//
//  ContentView.swift
//  Bagel
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showInspector = false

    var body: some View {
        NavigationSplitView {
            ProjectsView()
                .navigationTitle("Projects")
        } content: {
            DevicesView()
                .navigationTitle("Devices")
        } detail: {
            PacketsView()
                .inspector(isPresented: $showInspector) {
                    DetailView()
                        .inspectorColumnWidth(min: 280, ideal: 380, max: 640)
                }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onReceive(store.$selectedPacket) { packet in
            if packet != nil { showInspector = true }
        }
    }
}
