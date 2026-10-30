import SwiftUI

struct AnalyticsView: View {
    @StateObject private var vm = AnalyticsViewModel()

    var body: some View {
        NavigationView {
            VStack {
                periodSelector
                if vm.selectedPeriod == .custom { customDatePickers }
                Button("Refresh") { Task { await vm.fetch() } }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 8)

                content
            }
            .navigationTitle("Analytics")
            .task { await vm.fetch() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - UI blocks
    private var periodSelector: some View {
        Picker("Period", selection: $vm.selectedPeriod) {
            ForEach(AnalyticsViewModel.SummaryPeriod.allCases) {
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var customDatePickers: some View {
        HStack {
            DatePicker("Start", selection: $vm.customStart, displayedComponents: .date)
            DatePicker("End",   selection: $vm.customEnd,   displayedComponents: .date)
        }
        .datePickerStyle(.compact)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
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
                Text(vm.overallBalance, format: .currency(code: "USD"))
                    .font(.title2).foregroundColor(.blue)
                Spacer()
            }
        }
    }

    private var accountsSection: some View {
        Section("By Account") {
            ForEach(vm.accounts) { acc in
                HStack {
                    Text(acc.name)
                    Spacer()
                    Text(acc.balance, format: .currency(code: "USD"))
                }
            }
        }
    }

    private var summarySection: some View {
        Group {
            if let s = vm.summary {
                Section(vm.selectedPeriod.title.capitalized) {
                    summaryRow("Income",  s.incomeSum,  .green)
                    summaryRow("Expense", s.expenseSum, .red)
                    summaryRow("Net",     s.netSum,
                               s.netSum >= 0 ? .green : .red, bold: true)
                }
            }
        }
    }

    private var recentSection: some View {
        Group {
            if !vm.recentTx.isEmpty {
                Section("Recent Transactions") {
                    ForEach(vm.recentTx) { tx in
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(tx.type == "EX" ? .red : .green)
                            VStack(alignment: .leading) {
                                Text(tx.category)
                                Text(tx.date, format: .dateTime.year().month().day())
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(tx.amount, format: .currency(code: "USD"))
                                .foregroundColor(tx.type == "EX" ? .red : .green)
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
