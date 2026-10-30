//
//  AnalyticsModels.swift
//  BudgetTracker
//

import Foundation

// MARK: - Helpers
private func parseDouble(_ str: String) -> Double {
    Double(str) ?? 0
}

// MARK: - Account item
struct AnalyticsAccount: Codable, Identifiable {
    let id: Int
    let name: String
    let balance: Double

    enum CodingKeys: String, CodingKey { case id, name, balance }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id   = try container.decode(Int.self,    forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        if let decodedDouble = try? container.decode(Double.self, forKey: .balance) {
            balance = decodedDouble
        } else {
            let balanceText = try container.decode(String.self, forKey: .balance)
            balance = parseDouble(balanceText)
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
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // accounts are optional
        accounts = (try? container.decode([AnalyticsAccount].self,
                                  forKey: .accounts)) ?? []

        // overall_balance may be a string or a number
        if let decodedDouble = try? container.decode(Double.self, forKey: .overallBalance) {
            overallBalance = decodedDouble
        } else if let str = try? container.decode(String.self,
                                         forKey: .overallBalance) {
            overallBalance = parseDouble(str)
        } else {
            overallBalance = 0
        }
    }
}
