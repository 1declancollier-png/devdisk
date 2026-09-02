import SwiftUI

@main
struct DevDiskApp: App {
    var body: some Scene {
        WindowGroup("devdisk") {
            ContentView()
        }
        .defaultSize(width: 720, height: 560)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
