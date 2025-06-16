import SwiftUI

struct SetBudgetView: View {
    @State private var budgetLimit: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // Білий фон

            VStack(spacing: 20) {
                Spacer().frame(height: 50) // Відступ зверху

                // Заголовок
                Text("Set Monthly Budget")
                    .font(.custom("AbhayaLibre-ExtraBold", size: 36))
                    .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))
                    .padding(.bottom, 20)

                // Поле для вводу бюджету
                TextField("Enter Budget Limit", text: $budgetLimit)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95)) // Світло-сірий фон
                    .cornerRadius(10)
                    .font(.custom("Inconsolata", size: 20))
                    .foregroundColor(.black)
                    .frame(width: 300)

                // Кнопка "Save Budget"
                Button(action: saveBudget) {
                    Text("Save Budget")
                        .font(.custom("Inconsolata", size: 28))
                        .foregroundColor(.white)
                        .frame(width: 239, height: 63)
                        .background(Color(red: 0.27, green: 0.20, blue: 0.18)) // Темно-коричневий колір
                        .cornerRadius(20)
                }
                .padding(.top, 10)

                Spacer()

                // Повідомлення
                Text("Manage your monthly spending goals easily")
                    .font(.custom("Inconsolata", size: 16))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Budget"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func saveBudget() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserID") as? Int64,
              let limit = Double(budgetLimit) else {
            alertMessage = "Invalid input. Please enter a valid number."
            showAlert = true
            return
        }
        do {
            try DatabaseManager.shared.setBudget(userId: userId, limit: limit)
            alertMessage = "Budget limit set successfully"
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
        }
        showAlert = true
    }
}
