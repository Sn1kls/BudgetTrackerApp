import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {

    // MARK: - Published
    @Published var accounts:       [AnalyticsAccount] = []
    @Published var overallBalance  : Double           = 0
    @Published var recentTransactions        : [Transaction]    = []
    @Published var summary         : SummaryResponse?
    @Published var isLoading       : Bool  = false
    @Published var errorMessage    : String?

    @Published var selectedPeriod: SummaryPeriod = .thisMonth
    @Published var customStart   : Date = Calendar.current.date(from:
                                  Calendar.current.dateComponents([.year, .month], from: Date()))!
    @Published var customEnd     : Date = Date()

    enum SummaryPeriod: String, CaseIterable, Identifiable {
        case thisMonth = "this_month"
        case thisWeek  = "this_week"
        case custom    = "custom"

        var id: Self { self }
        var title: String {
            switch self {
            case .thisMonth: return "This month"
            case .thisWeek:  return "This week"
            case .custom:    return "Custom"
            }
        }
    }

    // MARK: - Private
    private let network = NetworkService.shared

    // MARK: - Public API
    func fetch() async {
        isLoading = true; defer { isLoading = false }
        errorMessage = nil
        
        async let analytics: AnalyticsResponse = {
            do { return try await network.fetchAnalytics() }
            catch { print("⛔️ analytics decode error:", error); throw error }
        }()
        
        async let transactions: [Transaction] = {
            do { return try await network.fetchTransactions() }
            catch { print("⛔️ transactions decode error:", error); throw error }
        }()
        
        async let summary = fetchSummaryForSelectedPeriod()

        do {
            let (analyticsResponse, allTransactions, summaryResponse) = try await (analytics, transactions, summary)
            print("👉 decoded overall =", analyticsResponse.overallBalance)
            accounts       = analyticsResponse.accounts
            overallBalance = analyticsResponse.overallBalance
            recentTransactions       = allTransactions.sorted(by: { $0.date > $1.date }).prefix(5).map { $0 }
            self.summary   = summaryResponse
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // MARK: - Helpers
    private func fetchSummaryForSelectedPeriod() async throws -> SummaryResponse {
        switch selectedPeriod {
        case .thisMonth: return try await network.fetchSummary(period: "this_month")
        case .thisWeek:  return try await network.fetchSummary(period: "this_week")
        case .custom:    return try await network.fetchSummary(
                            period: nil, start: customStart, end: customEnd)
        }
    }
}
