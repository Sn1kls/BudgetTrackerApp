//
//  SummaryResponse.swift
//  BudgetTracker
//

import Foundation

/// { "income_sum":"22.00", "expense_sum":"5.00",
///   "net_sum":"17.00",    "currency":"USD" }
struct SummaryResponse: Codable {
    @LosslessDouble var incomeSum:  Double = 0
    @LosslessDouble var expenseSum: Double = 0
    @LosslessDouble var netSum:     Double = 0
    let currency: String?           // may be absent

    enum CodingKeys: String, CodingKey {
        case incomeSum  = "income_sum"
        case expenseSum = "expense_sum"
        case netSum     = "net_sum"
        case currency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        _incomeSum  = (try? LosslessDouble(from:
                          container.superDecoder(forKey: .incomeSum)))
                   ?? LosslessDouble(wrappedValue: 0)

        _expenseSum = (try? LosslessDouble(from:
                          container.superDecoder(forKey: .expenseSum)))
                   ?? LosslessDouble(wrappedValue: 0)

        _netSum     = (try? LosslessDouble(from:
                          container.superDecoder(forKey: .netSum)))
                   ?? LosslessDouble(wrappedValue: 0)

        currency = try? container.decodeIfPresent(String.self, forKey: .currency)
    }
}
