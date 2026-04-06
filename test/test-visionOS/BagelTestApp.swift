import SwiftUI
import Bagel

@main
struct BagelTestApp: App {
    init() {
        Bagel.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
