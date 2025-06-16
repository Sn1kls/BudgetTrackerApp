import SwiftUI

struct CreatingTransactionsView: View {
    @State private var amount: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var selectedType: String = "Income"
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let transactionTypes = ["Income", "Expense"]
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // Білий фон

            VStack(spacing: 20) {
                Spacer().frame(height: 20) // Відступ зверху
                
                // Заголовок
                Text("Add Transaction")
                    .font(.custom("AbhayaLibre-ExtraBold", size: 36))
                    .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))

                // Picker для вибору типу транзакції
                Picker("Type", selection: $selectedType) {
                    ForEach(transactionTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 30)

                // Поле "Amount"
                TextField("Amount", text: $amount)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)
                    .keyboardType(.decimalPad)

                // Поле "Category"
                TextField("Category", text: $category)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)

                // Поле "Description"
                TextField("Description", text: $description)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)

                // Кнопка "Add Transaction"
                Button(action: saveTransaction) {
                    Text("Add Transaction")
                        .font(.custom("Inconsolata", size: 20))
                        .foregroundColor(Color(red: 0.85, green: 0.80, blue: 0.75))
                        .frame(width: 239, height: 50)
                        .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                        .cornerRadius(10)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Transaction"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveTransaction() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserID") as? Int64,
              let transactionAmount = Double(amount), !category.isEmpty else {
            alertMessage = "All fields are required"
            showAlert = true
            return
        }
        do {
            try DatabaseManager.shared.addTransaction(
                userId: userId,
                type: selectedType,
                amount: transactionAmount,
                category: category,
                description: description,
                date: Date()
            )
            alertMessage = "Transaction added successfully"
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
        }
        showAlert = true
    }
}
