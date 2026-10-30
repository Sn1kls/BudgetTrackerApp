import SwiftUI

struct AccountFormView: View {
    @Environment(\.presentationMode) var pm
    @ObservedObject var viewModel: AccountsViewModel
    var account: Account?

    @State private var name: String
    @State private var balance: String

    init(viewModel: AccountsViewModel, account: Account? = nil) {
        self.viewModel = viewModel
        self.account   = account
        _name    = State(initialValue: account?.name ?? "")
        _balance = State(initialValue: account != nil ? String(account!.balance) : "")
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Balance", text: $balance)
                    .keyboardType(.decimalPad)

                Button(account == nil ? "Add" : "Update") {
                    save()
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(account == nil ? "New Account" : "Edit Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { pm.wrappedValue.dismiss() }
                }
            }
            .alert("Error",
                   isPresented: .constant(viewModel.errorMessage != nil),
                   actions: { Button("OK") { viewModel.errorMessage = nil } },
                   message: { Text(viewModel.errorMessage ?? "") })
        }
    }

    private func save() {
        guard !name.isEmpty, let bal = Double(balance) else {
            viewModel.errorMessage = "Please enter a valid name and balance"
            return
        }

        // Build just the fields the API expects (id=0 for create)
        let acc = Account(
            id: account?.id ?? 0,
            name: name,
            balance: bal,
            owner: 0 // will be ignored on create; server uses request.user
        )

        Task {
            if account == nil {
                await viewModel.createAccount(acc)
            } else {
                await viewModel.updateAccount(acc)
            }
            if viewModel.errorMessage == nil {
                pm.wrappedValue.dismiss()
            }
        }
    }
}
