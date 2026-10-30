import Foundation

struct Transaction: Codable, Identifiable {
    let id: Int
    let type: String
    @LosslessDouble var amount: Double
    let category: String
    let description: String
    let date: Date
    let account: Int

    enum CodingKeys: String, CodingKey {
        case id, type, amount, category, description, account, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id       = try container.decode(Int.self,    forKey: .id)
        type     = try container.decode(String.self, forKey: .type)
        _amount  = try LosslessDouble(from: container.superDecoder(forKey: .amount))
        category = try container.decode(String.self, forKey: .category)        // backend returns "" rather than null
        description = try container.decode(String.self, forKey: .description)
        account  = try container.decode(Int.self,    forKey: .account)

        // ISO-8601 with a Z suffix
        date = try ISO8601DateFormatter().date(from: container.decode(String.self, forKey: .date))
               ?? { throw DecodingError.dataCorruptedError(
                        forKey: .date, in: container,
                        debugDescription: "Bad ISO-8601") }()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(String(format: "%.2f", amount), forKey: .amount)
        try container.encode(category,    forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(account,     forKey: .account)
        try container.encode(ISO8601DateFormatter().string(from: date), forKey: .date)
    }

    // convenience init for forms
    init(id: Int = 0,
         type: String,
         amount: Double,
         category: String,
         description: String,
         date: Date,
         account: Int = 0)
    {
        self.id = id
        self.type = type
        self._amount = LosslessDouble(wrappedValue: amount)
        self.category = category
        self.description = description
        self.date = date
        self.account = account
    }
}
