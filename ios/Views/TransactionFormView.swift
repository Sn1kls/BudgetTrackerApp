import SwiftUI

struct TransactionFormView: View {
    // MARK: - Environment / VM
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject          var accountsViewModel: AccountsViewModel
    @ObservedObject             var viewModel : TransactionsViewModel
    var transaction: Transaction?

    // MARK: - Form State
    @State private var selectedAccountID: Int? = nil
    @State private var type    = "IN"
    @State private var amount  = ""
    @State private var category = ""
    @State private var description = ""
    @State private var date    = Date()

    // MARK: - Consts
    private let types       = ["IN","EX"]
    private let typeLabels  = ["IN":"Income","EX":"Expense"]

    // MARK: - Derived
    private var formIsValid: Bool {
        guard
            selectedAccountID != nil,
            amount.decimalValue != nil,
            !category.isEmpty
        else { return false }
        return true
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Account picker, or a loader while accounts load
                if accountsViewModel.accounts.isEmpty {
                    ProgressView("Loading accounts…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Picker("Account", selection: $selectedAccountID) {
                        ForEach(accountsViewModel.accounts) { account in
                            Text(account.name).tag(Optional(account.id))   // tag must be Optional to match the selection
                        }
                    }
                }

                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) { code in
                        Text(typeLabels[code] ?? code).tag(code)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("Category", text: $category)
                TextField("Description", text: $description)
                DatePicker("Date", selection: $date, displayedComponents: .date)

                Button(transaction == nil ? "Add" : "Update") { save() }
                    .disabled(!formIsValid)
            }
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .alert("Error",
                   isPresented: .constant(viewModel.errorMessage != nil),
                   actions: { Button("OK") { viewModel.errorMessage = nil } },
                   message:  { Text(viewModel.errorMessage ?? "") })

            .onAppear(perform: setupInitialState)
            .onChange(of: accountsViewModel.accounts) { _ in setDefaultAccountIfNeeded() }
        }
    }

    // MARK: - Helpers
    private func setupInitialState() {
        if let editedTransaction = transaction {
            selectedAccountID = editedTransaction.account
            type              = editedTransaction.type
            amount            = String(editedTransaction.amount)
            category          = editedTransaction.category
            description       = editedTransaction.description
            date              = editedTransaction.date
        }
        setDefaultAccountIfNeeded()
    }

    /// Falls back to the first account if none is selected
    private func setDefaultAccountIfNeeded() {
        if selectedAccountID == nil {
            selectedAccountID = accountsViewModel.accounts.first?.id
        }
    }

    private func save() {
        guard
            let accountID = selectedAccountID,
            let parsedAmount = amount.decimalValue,
            !category.isEmpty
        else {
            viewModel.errorMessage = "All fields are required"
            return
        }

        let savedTransaction = Transaction(
            id:          transaction?.id ?? 0,
            type:        type,
            amount:      parsedAmount,
            category:    category,
            description: description,
            date:        date,
            account:     accountID
        )

        Task {
            if transaction == nil {
                await viewModel.createTransaction(savedTransaction)
            } else {
                await viewModel.updateTransaction(savedTransaction)
            }
            // Keep the form open on failure so the input is not lost.
            if viewModel.errorMessage == nil {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
