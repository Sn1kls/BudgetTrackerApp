import SwiftUI

struct AccountsListView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @State private var showForm = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.accounts) { account in
                        NavigationLink(account.name) {
                            AccountFormView(viewModel: viewModel, account: account)
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                Button { showForm = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showForm) {
                AccountFormView(viewModel: viewModel)
            }
            .task { await viewModel.fetchAccounts() }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}
