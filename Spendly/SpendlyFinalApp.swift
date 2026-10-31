import SwiftUI

@main
struct SpendlyFinalApp: App {
    @StateObject private var appSettings  = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}
