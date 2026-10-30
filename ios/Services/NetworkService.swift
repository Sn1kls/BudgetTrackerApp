import Foundation

enum NetworkError: LocalizedError {
    case badResponse
    case sessionExpired
    case statusCode(Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Unexpected response from the server."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case let .statusCode(code, message):
            return message ?? "Request failed (HTTP \(code))."
        }
    }

    /// Collects the messages from a DRF error body, e.g. {"password": ["Too short."]}.
    static func message(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let messages = json.keys.sorted().flatMap { key -> [String] in
            if let list = json[key] as? [String] { return list }
            if let text = json[key] as? String { return [text] }
            return []
        }
        return messages.isEmpty ? nil : messages.joined(separator: "\n")
    }
}

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
}

// An actor, so parallel requests that hit 401 share one token refresh.
actor NetworkService {
    static let shared = NetworkService()
    private init(session: URLSession = .shared) { self.session = session }

    // MARK: - Private
    private let session: URLSession
    private var refreshTask: Task<Void, Error>?
    private let decoder: JSONDecoder = {
        let configuredDecoder = JSONDecoder()
        configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
        configuredDecoder.dateDecodingStrategy = .iso8601
        return configuredDecoder
    }()
    private let encoder: JSONEncoder = {
        let configuredEncoder = JSONEncoder()
        configuredEncoder.keyEncodingStrategy = .convertToSnakeCase
        configuredEncoder.dateEncodingStrategy = .iso8601
        return configuredEncoder
    }()

    // MARK: - Request helper
    private func request(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        authenticated: Bool = false,
        retryOnUnauthorized: Bool = true
    ) async throws -> Data {
        var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw NetworkError.badResponse }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authenticated, let token = KeychainManager.shared.getAccessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        #if DEBUG
        print("▶️ \(method) \(url.absoluteString)")
        #endif

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.badResponse }

        if httpResponse.statusCode == 401, authenticated, retryOnUnauthorized {
            try await refreshAccessToken()
            return try await request(
                path: path, method: method, query: query, body: body,
                authenticated: true, retryOnUnauthorized: false
            )
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode, message: NetworkError.message(from: data))
        }
        return data
    }

    private func refreshAccessToken() async throws {
        if let refreshTask { return try await refreshTask.value }

        let task = Task {
            guard let refresh = KeychainManager.shared.getRefreshToken() else {
                throw NetworkError.sessionExpired
            }
            let tokens = try await refreshToken(refresh: refresh)
            KeychainManager.shared.saveAccessToken(tokens.access)
            // The backend rotates refresh tokens and blacklists the old one.
            if let newRefresh = tokens.refresh {
                KeychainManager.shared.saveRefreshToken(newRefresh)
            }
        }
        refreshTask = task
        defer { refreshTask = nil }

        do {
            try await task.value
        } catch NetworkError.statusCode(401, _), NetworkError.sessionExpired {
            // Only a rejected refresh token ends the session, not e.g. a lost connection.
            KeychainManager.shared.deleteTokens()
            await MainActor.run {
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            }
            throw NetworkError.sessionExpired
        }
    }

    // MARK: - Decoding
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("⛔️ Decoding \(T.self) failed:", error)
            #endif
            throw error
        }
    }

    private func json(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    // MARK: - Auth
    func login(username: String, password: String) async throws -> TokenObtainPair {
        let data = try await request(
            path: "login/", method: "POST",
            body: json(["username": username, "password": password])
        )
        return try decode(TokenObtainPair.self, from: data)
    }

    func register(username: String, email: String, password: String) async throws -> RegisterResponse {
        let payload = RegisterRequest(username: username, email: email, password: password)
        let data = try await request(path: "register/", method: "POST", body: encoder.encode(payload))
        return try decode(RegisterResponse.self, from: data)
    }

    func refreshToken(refresh: String) async throws -> TokenRefresh {
        let data = try await request(
            path: "token/refresh/", method: "POST", body: json(["refresh": refresh])
        )
        return try decode(TokenRefresh.self, from: data)
    }

    func logout(refresh: String) async throws {
        _ = try await request(
            path: "logout/", method: "POST",
            body: json(["refresh": refresh]), authenticated: true
        )
    }

    // MARK: - Accounts
    func fetchAccounts() async throws -> [Account] {
        let data = try await request(path: "accounts/", authenticated: true)
        return try decode([Account].self, from: data)
    }

    func createAccount(_ account: Account) async throws -> Account {
        let data = try await request(
            path: "accounts/", method: "POST",
            body: json(["name": account.name, "balance": account.balance]),
            authenticated: true
        )
        return try decode(Account.self, from: data)
    }

    func updateAccount(_ account: Account) async throws -> Account {
        let data = try await request(
            path: "accounts/\(account.id)/", method: "PUT",
            body: json(["name": account.name, "balance": account.balance]),
            authenticated: true
        )
        return try decode(Account.self, from: data)
    }

    // MARK: - Transactions
    func fetchTransactions() async throws -> [Transaction] {
        let data = try await request(path: "transactions/", authenticated: true)
        return try decode([Transaction].self, from: data)
    }

    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        let data = try await request(
            path: "transactions/", method: "POST",
            body: json(transactionBody(transaction)), authenticated: true
        )
        return try decode(Transaction.self, from: data)
    }

    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        let data = try await request(
            path: "transactions/\(transaction.id)/", method: "PUT",
            body: json(transactionBody(transaction)), authenticated: true
        )
        return try decode(Transaction.self, from: data)
    }

    func deleteTransaction(id: Int) async throws {
        _ = try await request(path: "transactions/\(id)/", method: "DELETE", authenticated: true)
    }

    private func transactionBody(_ transaction: Transaction) -> [String: Any] {
        [
            "account": transaction.account, "type": transaction.type, "amount": transaction.amount,
            "category": transaction.category, "description": transaction.description,
            "date": ISO8601DateFormatter().string(from: transaction.date),
        ]
    }

    // MARK: - Analytics
    func fetchAnalytics() async throws -> AnalyticsResponse {
        let data = try await request(path: "analytics/", authenticated: true)
        return try decode(AnalyticsResponse.self, from: data)
    }

    /// period=this_month / this_week, or start+end (YYYY-MM-DD)
    func fetchSummary(period: String? = "this_month",
                      start: Date? = nil,
                      end: Date? = nil) async throws -> SummaryResponse
    {
        var query: [URLQueryItem] = []
        if let period {
            query = [URLQueryItem(name: "period", value: period)]
        } else if let start, let end {
            query = [
                URLQueryItem(name: "start", value: start.apiDay),
                URLQueryItem(name: "end", value: end.apiDay),
            ]
        }
        let data = try await request(path: "analytics/summary/", query: query, authenticated: true)
        return try decode(SummaryResponse.self, from: data)
    }
}
