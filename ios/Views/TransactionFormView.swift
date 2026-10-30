import SwiftUI

struct TransactionFormView: View {
    // MARK: - Environment / VM
    @Environment(\.presentationMode) private var pm
    @EnvironmentObject          var accountsVM: AccountsViewModel
    @ObservedObject             var viewModel : TransactionsViewModel
    var transaction: Transaction?

    // MARK: - Form State
    @State private var selectedAccountID: Int? = nil          // 👈  nil, поки акаунти не підвантажились
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
            Double(amount) != nil,
            !category.isEmpty
        else { return false }
        return true
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // 1️⃣ Account picker або лоадер
                if accountsVM.accounts.isEmpty {
                    ProgressView("Loading accounts…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Picker("Account", selection: $selectedAccountID) {
                        ForEach(accountsVM.accounts) { acc in
                            Text(acc.name).tag(Optional(acc.id))   // Optional(tag:)
                        }
                    }
                }

                // 2️⃣ Type
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) { code in
                        Text(typeLabels[code] ?? code).tag(code)
                    }
                }
                .pickerStyle(.segmented)

                // 3️⃣ Amount / Category / Description / Date
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("Category", text: $category)
                TextField("Description", text: $description)
                DatePicker("Date", selection: $date, displayedComponents: .date)

                // 4️⃣ Save button
                Button(transaction == nil ? "Add" : "Update") { save() }
                    .disabled(!formIsValid)
            }
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { pm.wrappedValue.dismiss() }
                }
            }
            .alert("Error",
                   isPresented: .constant(viewModel.errorMessage != nil),
                   actions: { Button("OK") { viewModel.errorMessage = nil } },
                   message:  { Text(viewModel.errorMessage ?? "") })

            // ⚙️  Ініціалізація стейту
            .onAppear(perform: setupInitialState)
            .onChange(of: accountsVM.accounts) { _ in setDefaultAccountIfNeeded() }
        }
    }

    // MARK: - Helpers
    private func setupInitialState() {
        if let tx = transaction {
            // Режим редагування
            selectedAccountID = tx.account
            type              = tx.type
            amount            = String(tx.amount)
            category          = tx.category
            description       = tx.description
            date              = tx.date
        }
        setDefaultAccountIfNeeded()
    }

    /// Якщо акаунт ще не вибрано, підставляємо перший у списку
    private func setDefaultAccountIfNeeded() {
        if selectedAccountID == nil {
            selectedAccountID = accountsVM.accounts.first?.id
        }
    }

    private func save() {
        guard
            let accID = selectedAccountID,
            let amt   = Double(amount),
            !category.isEmpty
        else {
            viewModel.errorMessage = "All fields are required"
            return
        }

        let tx = Transaction(
            id:          transaction?.id ?? 0,
            type:        type,
            amount:      amt,
            category:    category,
            description: description,
            date:        date,
            account:     accID
        )

        Task {
            do {
                if transaction == nil {
                    _ = try await viewModel.createTransaction(tx)
                } else {
                    _ = try await viewModel.updateTransaction(tx)
                }
                pm.wrappedValue.dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
