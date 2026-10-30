import SwiftUI

struct AccountsListView: View {
    @StateObject private var vm = AccountsViewModel()
    @State private var showForm = false

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else {
                    List(vm.accounts) { acc in
                        NavigationLink(acc.name) {
                            AccountFormView(viewModel: vm, account: acc)
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
                AccountFormView(viewModel: vm)
            }
            .task { await vm.fetchAccounts() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }
}
