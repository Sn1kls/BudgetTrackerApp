//
//  AnalyticsModels.swift
//  BudgetTracker
//

import Foundation

// MARK: - Помічник
private func parseDouble(_ str: String) -> Double {
    Double(str) ?? 0
}

// MARK: - Account item
struct AnalyticsAccount: Codable, Identifiable {
    let id: Int
    let name: String
    let balance: Double     // ← звичайний Double

    enum CodingKeys: String, CodingKey { case id, name, balance }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id   = try c.decode(Int.self,    forKey: .id)
        name = try c.decode(String.self, forKey: .name)

        if let dbl = try? c.decode(Double.self, forKey: .balance) {
            balance = dbl
        } else {
            let s = try c.decode(String.self, forKey: .balance)
            balance = parseDouble(s)
        }
    }
}

// MARK: - /api/analytics/ payload
struct AnalyticsResponse: Codable {
    let accounts: [AnalyticsAccount]
    let overallBalance: Double

    enum CodingKeys: String, CodingKey {
        case accounts
        case overallBalance = "overall_balance"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // accounts  — не критично, якщо нема
        accounts = (try? c.decode([AnalyticsAccount].self,
                                  forKey: .accounts)) ?? []

        // overall_balance  — рядок або число
        if let dbl = try? c.decode(Double.self, forKey: .overallBalance) {
            overallBalance = dbl
        } else if let str = try? c.decode(String.self,
                                         forKey: .overallBalance) {
            overallBalance = parseDouble(str)
        } else {
            overallBalance = 0
        }
    }
}
