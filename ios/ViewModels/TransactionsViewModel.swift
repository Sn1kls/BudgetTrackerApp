import Foundation

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared

    func fetchTransactions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            transactions = try await network.fetchTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTransaction(_ tx: Transaction) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let created = try await network.createTransaction(tx)
            transactions.append(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTransaction(_ tx: Transaction) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let updated = try await network.updateTransaction(tx)
            if let idx = transactions.firstIndex(where: { $0.id == updated.id }) {
                transactions[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func deleteTransaction(_ tx: Transaction) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await NetworkService.shared.deleteTransaction(id: tx.id)
            // remove from the local list:
            transactions.removeAll { $0.id == tx.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
