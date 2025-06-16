import SwiftUI

struct CheckingAnalyticsView: View {
    @State private var incomeTransactions: [Transaction] = []
    @State private var expenseTransactions: [Transaction] = []
    @State private var totalIncome: Double = 0.0
    @State private var totalExpense: Double = 0.0

    var body: some View {
        VStack {
            Text("Analytics")
                .font(.largeTitle)
                .bold()
                .padding()

            // Total Income & Expense
            HStack {
                VStack {
                    Text("Total Income")
                        .font(.headline)
                    Text(String(format: "%.2f", totalIncome))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("Total Expenses")
                        .font(.headline)
                    Text(String(format: "%.2f", totalExpense))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            Divider()

            // List of Income Transactions
            Text("Income Transactions")
                .font(.headline)
                .padding(.top, 10)
            List(incomeTransactions) { transaction in
                VStack(alignment: .leading) {
                    Text(transaction.category)
                        .font(.subheadline)
                        .bold()
                    Text(transaction.description)
                        .font(.caption)
                    Text(String(format: "%.2f", transaction.amount))
                        .foregroundColor(.green)
                        .font(.headline)
                }
            }

            // List of Expense Transactions
            Text("Expense Transactions")
                .font(.headline)
                .padding(.top, 10)
            List(expenseTransactions) { transaction in
                VStack(alignment: .leading) {
                    Text(transaction.category)
                        .font(.subheadline)
                        .bold()
                    Text(transaction.description)
                        .font(.caption)
                    Text(String(format: "%.2f", transaction.amount))
                        .foregroundColor(.red)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            loadAnalytics()
        }
    }

    private func loadAnalytics() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserID") as? Int64 else { return }
        do {
            // Завантаження аналітики
            let analytics = try DatabaseManager.shared.getAnalytics(userId: userId)
            totalIncome = analytics.totalIncome
            totalExpense = analytics.totalExpense

            // Завантаження транзакцій
            incomeTransactions = try DatabaseManager.shared.fetchTransactions(userId: userId, type: "Income")
            expenseTransactions = try DatabaseManager.shared.fetchTransactions(userId: userId, type: "Expense")
        } catch {
            print("Failed to load analytics: \(error)")
        }
    }
}
