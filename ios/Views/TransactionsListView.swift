import SwiftUI

struct TransactionsListView: View {
    @StateObject private var txVM       = TransactionsViewModel()
    @StateObject private var accountsVM = AccountsViewModel()
    @State private var showNewForm      = false
    @State private var editingTx: Transaction?

    var body: some View {
        NavigationView {
            List {
                ForEach(txVM.transactions) { tx in
                    // Стандартний рядок: дві колонки
                    HStack {
                        Text(tx.amount, format: .currency(code: "USD"))
                        Spacer()
                        Text(tx.typeDisplay)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    // натискання відкриває форму з передачею tx → редагування
                    .onTapGesture {
                        editingTx = tx
                    }
                    // свайп-декоратор для видалення
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await txVM.deleteTransaction(tx) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { idxs in
                    for idx in idxs {
                        let tx = txVM.transactions[idx]
                        Task { await txVM.deleteTransaction(tx) }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Форма створення (нетранзакція → нова)
            .sheet(isPresented: $showNewForm) {
                TransactionFormView(viewModel: txVM)
                    .environmentObject(accountsVM)
            }
            // Форма редагування (якщо editingTx != nil)
            .sheet(item: $editingTx) { tx in
                TransactionFormView(viewModel: txVM, transaction: tx)
                    .environmentObject(accountsVM)
            }
            .task {
                await accountsVM.fetchAccounts()
                await txVM.fetchTransactions()
            }
            .alert("Error", isPresented: .constant(txVM.errorMessage != nil)) {
                Button("OK") { txVM.errorMessage = nil }
            } message: {
                Text(txVM.errorMessage ?? "")
            }
        }
    }
}

/// Щоб sheet(item:) працював, Transaction має бути Identifiable (у вас воно є)…
/// І ми додаємо допоміжний пропертіз:
extension Transaction {
    var typeDisplay: String {
        switch type {
        case "IN": return "Income"
        case "EX": return "Expense"
        default:   return type
        }
    }
}
