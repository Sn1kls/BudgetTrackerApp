// frontend/App/BudgetTrackerApp.swift
import SwiftUI

@main
struct BudgetTrackerApp: App {
    // ▸ Головний (спільний) view-model авторизації
    @StateObject private var authVM = AuthViewModel()

    /// Запускається один раз, коли апка піднімається
    init() {
        // Перехоплюємо всі uncaught exception (Foundation/Obj-C layer)
        NSSetUncaughtExceptionHandler { exc in
            print("💥 Uncaught exception:", exc)
            print("💥 Stack trace:\n", exc.callStackSymbols.joined(separator: "\n"))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()                 // ← ваш кореневий SwiftUI контейнер
                .environmentObject(authVM)
        }
    }
}
