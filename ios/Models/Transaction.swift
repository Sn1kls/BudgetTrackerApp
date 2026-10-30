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
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id       = try c.decode(Int.self,    forKey: .id)
        type     = try c.decode(String.self, forKey: .type)
        _amount  = try LosslessDouble(from: c.superDecoder(forKey: .amount))
        category = try c.decode(String.self, forKey: .category)        // backend returns "" rather than null
        description = try c.decode(String.self, forKey: .description)
        account  = try c.decode(Int.self,    forKey: .account)

        // ISO-8601 with a Z suffix
        date = try ISO8601DateFormatter().date(from: c.decode(String.self, forKey: .date))
               ?? { throw DecodingError.dataCorruptedError(
                        forKey: .date, in: c,
                        debugDescription: "Bad ISO-8601") }()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(String(format: "%.2f", amount), forKey: .amount)
        try c.encode(category,    forKey: .category)
        try c.encode(description, forKey: .description)
        try c.encode(account,     forKey: .account)
        try c.encode(ISO8601DateFormatter().string(from: date), forKey: .date)
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
