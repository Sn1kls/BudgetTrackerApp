import SwiftUI

@main
struct BudgetTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    /// Runs once at launch
    init() {
        // Catch uncaught Foundation/Obj-C exceptions
        NSSetUncaughtExceptionHandler { exception in
            print("💥 Uncaught exception:", exception)
            print("💥 Stack trace:\n", exception.callStackSymbols.joined(separator: "\n"))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
