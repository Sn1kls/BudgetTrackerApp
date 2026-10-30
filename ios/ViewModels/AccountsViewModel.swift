import Foundation

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared

    func fetchAccounts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            accounts = try await network.fetchAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createAccount(_ account: Account) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let created = try await network.createAccount(account)
            accounts.append(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAccount(_ account: Account) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let updated = try await network.updateAccount(account)
            if let index = accounts.firstIndex(where: { $0.id == updated.id }) {
                accounts[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
