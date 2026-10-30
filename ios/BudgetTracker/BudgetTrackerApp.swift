import SwiftUI

@main
struct BudgetTrackerApp: App {
    @StateObject private var authVM = AuthViewModel()

    /// Runs once at launch
    init() {
        // Catch uncaught Foundation/Obj-C exceptions
        NSSetUncaughtExceptionHandler { exc in
            print("💥 Uncaught exception:", exc)
            print("💥 Stack trace:\n", exc.callStackSymbols.joined(separator: "\n"))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}
