import Foundation

// MARK: - Account

struct Account: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let balance: Double
    let owner: Int

    // Memberwise init for forms and view models
    init(id: Int = 0,
         name: String,
         balance: Double,
         owner: Int = 0)
    {
        self.id = id
        self.name = name
        self.balance = balance
        self.owner = owner
    }

    // Same CodingKeys + custom decoding
    enum CodingKeys: String, CodingKey {
        case id, name, owner, balance
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try c.decode(Int.self,    forKey: .id)
        name    = try c.decode(String.self, forKey: .name)
        owner   = try c.decode(Int.self,    forKey: .owner)
        let balString = try c.decode(String.self, forKey: .balance)
        balance = Double(balString) ?? 0
    }
}

// MARK: - Auth models

struct TokenObtainPair: Codable {
    let refresh: String
    let access: String
}

struct TokenRefresh: Codable {
    let access: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct RegisterResponse: Codable {
    let message: String
}
