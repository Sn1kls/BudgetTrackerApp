import SwiftUI

struct TransactionDetailView: View {
    @EnvironmentObject var accountsVM: AccountsViewModel
    let transaction: Transaction

    var body: some View {
        Form {
            Section(header: Text("Amount")) {
                Text(transaction.amount, format: .currency(code: "USD"))
            }
            Section(header: Text("Type")) {
                Text(transaction.typeDisplay)
            }
            Section(header: Text("Category")) {
                Text(transaction.category)
            }
            Section(header: Text("Description")) {
                Text(transaction.description)
            }
            Section(header: Text("Date")) {
                Text(transaction.date, format: .dateTime.year().month().day().hour().minute())
            }
            Section(header: Text("Account")) {
                Text(
                    accountsVM.accounts
                        .first(where: { $0.id == transaction.account })?
                        .name
                    ?? "—"
                )
            }
        }
        .navigationTitle("Details")
    }
}
