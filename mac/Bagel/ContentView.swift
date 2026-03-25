//
//  ContentView.swift
//  Bagel
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationSplitView {
            ProjectsView()
                .navigationTitle("Projects")
        } content: {
            DevicesView()
                .navigationTitle("Devices")
        } detail: {
            VSplitView {
                PacketsView()
                    .frame(minHeight: 150)
                if store.selectedPacket != nil {
                    DetailView()
                        .frame(minHeight: 200)
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
    }
}
