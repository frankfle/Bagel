//
//  ProjectsView.swift
//  Bagel
//

import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedID: ObjectIdentifier?

    var body: some View {
        List(store.projectControllers, selection: $selectedID) { project in
            Text(project.projectName ?? "Unknown")
                .accessibilityLabel("Project: \(project.projectName ?? "Unknown")")
                .accessibilityAddTraits(store.selectedProject?.id == project.id ? [.isSelected] : [])
        }
        .accessibilityLabel("Projects")
        .onChange(of: selectedID) { _, newID in
            guard let id = newID,
                  let project = store.projectControllers.first(where: { $0.id == id })
            else { return }
            store.selectProject(project)
        }
        .onReceive(store.$selectedProject) { project in
            selectedID = project?.id
        }
    }
}
