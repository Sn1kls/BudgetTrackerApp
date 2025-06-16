import SwiftUI

struct HomeView: View {
    let userEmail: String
    @State private var budget: Double = 0.0
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer().frame(height: 20)

                    // Заголовок
                    Text("BUTGET TRACKER")
                        .font(.custom("AbhayaLibre-ExtraBold", size: 36))
                        .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))

                    // Підзаголовок
                    Text("WELCOME, \(userEmail.uppercased())")
                        .font(.custom("AbhayaLibre-Medium", size: 24))
                        .foregroundColor(Color(red: 0.70, green: 0.60, blue: 0.50))

                    // Бюджет
                    Text("Your Budget: \(String(format: "%.2f", budget))")
                        .font(.custom("Inconsolata", size: 28))
                        .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.40))

                    Spacer().frame(height: 30)

                    // Кнопка "Add Transaction"
                    NavigationLink(destination: CreatingTransactionsView()) {
                        Text("Add Transaction")
                            .frame(maxWidth: .infinity)
                            .font(.custom("Inconsolata", size: 20))
                            .padding()
                            .foregroundColor(Color(red: 0.85, green: 0.80, blue: 0.75))
                            .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                            .cornerRadius(10)
                    }
                    .frame(width: 300)

                    // Кнопка "Check Analytics"
                    NavigationLink(destination: CheckingAnalyticsView()) {
                        Text("Check Analytics")
                            .frame(maxWidth: .infinity)
                            .font(.custom("Inconsolata", size: 20))
                            .padding()
                            .foregroundColor(Color(red: 0.85, green: 0.80, blue: 0.75))
                            .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                            .cornerRadius(10)
                    }
                    .frame(width: 300)

                    // Кнопка "Set Budget"
                    NavigationLink(destination: SetBudgetView()) {
                        Text("Set Budget")
                            .frame(maxWidth: .infinity)
                            .font(.custom("Inconsolata", size: 20))
                            .padding()
                            .foregroundColor(Color(red: 0.85, green: 0.80, blue: 0.75))
                            .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                            .cornerRadius(10)
                    }
                    .frame(width: 300)

                    Spacer()

                    // Логаут
                    Button(action: { showLogoutAlert = true }) {
                        Text("Logout")
                            .font(.custom("Inconsolata", size: 16))
                            .foregroundColor(Color(red: 0.70, green: 0.60, blue: 0.50))
                            .underline()
                    }
                    .padding(.bottom, 20)
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Logout"),
                            message: Text("Are you sure you want to logout?"),
                            primaryButton: .destructive(Text("Logout")) {
                                logoutUser()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding()
                .onAppear {
                    loadBudget()
                }
            }
        }
    }

    private func loadBudget() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserID") as? Int64 else { return }
        do {
            if let fetchedBudget = try DatabaseManager.shared.fetchBudget(userId: userId) {
                budget = fetchedBudget
            } else {
                budget = 0.0
            }
        } catch {
            print("Failed to fetch budget: \(error)")
        }
    }

    private func logoutUser() {
        UserDefaults.standard.removeObject(forKey: "loggedInUserID")
        UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: ContentView())
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}
