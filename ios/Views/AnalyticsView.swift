import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationView {
            VStack {
                periodSelector
                if viewModel.selectedPeriod == .custom { customDatePickers }
                Button("Refresh") { Task { await viewModel.fetch() } }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 8)

                content
            }
            .navigationTitle("Analytics")
            .task { await viewModel.fetch() }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - UI blocks
    private var periodSelector: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(AnalyticsViewModel.SummaryPeriod.allCases) {
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var customDatePickers: some View {
        HStack {
            DatePicker("Start", selection: $viewModel.customStart, displayedComponents: .date)
            DatePicker("End",   selection: $viewModel.customEnd,   displayedComponents: .date)
        }
        .datePickerStyle(.compact)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer(); ProgressView("Loading…"); Spacer()
        } else {
            List {
                totalSection
                accountsSection
                summarySection
                recentSection
            }
            .listStyle(.insetGrouped)
        }
    }

    private var totalSection: some View {
        Section("Total Balance") {
            HStack {
                Spacer()
                Text(viewModel.overallBalance, format: .currency(code: "USD"))
                    .font(.title2).foregroundColor(.blue)
                Spacer()
            }
        }
    }

    private var accountsSection: some View {
        Section("By Account") {
            ForEach(viewModel.accounts) { account in
                HStack {
                    Text(account.name)
                    Spacer()
                    Text(account.balance, format: .currency(code: "USD"))
                }
            }
        }
    }

    private var summarySection: some View {
        Group {
            if let summary = viewModel.summary {
                Section(viewModel.selectedPeriod.title.capitalized) {
                    summaryRow("Income",  summary.incomeSum,  .green)
                    summaryRow("Expense", summary.expenseSum, .red)
                    summaryRow("Net",     summary.netSum,
                               summary.netSum >= 0 ? .green : .red, bold: true)
                }
            }
        }
    }

    private var recentSection: some View {
        Group {
            if !viewModel.recentTransactions.isEmpty {
                Section("Recent Transactions") {
                    ForEach(viewModel.recentTransactions) { transaction in
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(transaction.type == "EX" ? .red : .green)
                            VStack(alignment: .leading) {
                                Text(transaction.category)
                                Text(transaction.date, format: .dateTime.year().month().day())
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(transaction.amount, format: .currency(code: "USD"))
                                .foregroundColor(transaction.type == "EX" ? .red : .green)
                        }
                    }
                }
            }
        }
    }

    private func summaryRow(_ label: String,
                            _ value: Double,
                            _ color: Color,
                            bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .foregroundColor(color)
                .fontWeight(bold ? .bold : .regular)
        }
    }
}
