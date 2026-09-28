import SwiftUI

@main
struct SeifertAusgabenApp: App {
  @StateObject private var store = ExpenseStore()

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
        .frame(minWidth: 1_050, minHeight: 700)
    }
    .windowStyle(.titleBar)
    .windowToolbarStyle(.unified)

    Settings {
      SettingsView(store: store)
        .frame(width: 480)
    }
  }
}
