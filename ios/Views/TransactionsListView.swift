import SwiftUI

struct TransactionsListView: View {
    @StateObject private var transactionsViewModel       = TransactionsViewModel()
    @StateObject private var accountsViewModel = AccountsViewModel()
    @State private var showNewForm      = false
    @State private var editingTransaction: Transaction?

    var body: some View {
        NavigationView {
            List {
                ForEach(transactionsViewModel.transactions) { transaction in
                    HStack {
                        Text(transaction.amount, format: .currency(code: "USD"))
                        Spacer()
                        Text(transaction.typeDisplay)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTransaction = transaction
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await transactionsViewModel.deleteTransaction(transaction) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let transaction = transactionsViewModel.transactions[index]
                        Task { await transactionsViewModel.deleteTransaction(transaction) }
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
            .sheet(isPresented: $showNewForm) {
                TransactionFormView(viewModel: transactionsViewModel)
                    .environmentObject(accountsViewModel)
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionFormView(viewModel: transactionsViewModel, transaction: transaction)
                    .environmentObject(accountsViewModel)
            }
            .task {
                await accountsViewModel.fetchAccounts()
                await transactionsViewModel.fetchTransactions()
            }
            .alert("Error", isPresented: .constant(transactionsViewModel.errorMessage != nil)) {
                Button("OK") { transactionsViewModel.errorMessage = nil }
            } message: {
                Text(transactionsViewModel.errorMessage ?? "")
            }
        }
    }
}

/// sheet(item:) needs Identifiable, so Transaction conforms to it.
extension Transaction {
    var typeDisplay: String {
        switch type {
        case "IN": return "Income"
        case "EX": return "Expense"
        default:   return type
        }
    }
}
