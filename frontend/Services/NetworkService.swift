import Foundation

enum NetworkError: Error {
    case badResponse
    case statusCode(Int)
}

// MARK: - ЄДИНИЙ singleton
final class NetworkService {
    static let shared = NetworkService()
    private init(session: URLSession = .shared) { self.session = session }

    // ───── Private ─────
    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private var accessToken: String? { KeychainManager.shared.getAccessToken() }

    // ───── Universal request helper ─────
    private func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        authenticated: Bool = false
    ) async throws -> (Data, HTTPURLResponse)
    {
        let url = APIConfig.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body { req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authenticated, let tok = accessToken {
            req.setValue("Bearer \(tok)", forHTTPHeaderField: "Authorization")
        }

        #if DEBUG
        print("▶️ \(method) \(url.absoluteString)")
        #endif

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw NetworkError.badResponse }
        return (data, http)
    }

    // ───── Generic decode with raw-dump on error ─────
    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        label: String
    ) throws -> T
    {
        do { return try decoder.decode(type, from: data) }
        catch {
            print("📦 RAW \(label):\n", String(data: data, encoding: .utf8) ?? "<non-UTF8>")
            print("⛔️ DECODE \(label) error:", error)
            throw error
        }
    }

    // MARK: – Auth
    func login(username: String, password: String) async throws -> TokenObtainPair {
        let body = try JSONSerialization.data(withJSONObject:
                    ["username": username, "password": password])
        let (data, resp) = try await request(
            path: "login/", method: "POST", body: body
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(TokenObtainPair.self, from: data)
    }

    func register(username: String, email: String, password: String) async throws -> RegisterResponse {
        let payload = RegisterRequest(username: username, email: email, password: password)
        let body = try encoder.encode(payload)
        let (data, resp) = try await request(
            path: "register/", method: "POST", body: body
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(RegisterResponse.self, from: data)
    }

    func refreshToken(refresh: String) async throws -> TokenRefresh {
        let body = try JSONSerialization.data(withJSONObject: ["refresh": refresh])
        let (data, resp) = try await request(
            path: "token/refresh/", method: "POST", body: body
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(TokenRefresh.self, from: data)
    }

    func logout(refresh: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["refresh": refresh])
        let (_, resp) = try await request(
            path: "logout/", method: "POST", body: body, authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
    }

    // MARK: – Accounts
    func fetchAccounts() async throws -> [Account] {
        let (data, resp) = try await request(path: "accounts/", authenticated: true)
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode([Account].self, from: data)
    }

    func createAccount(_ account: Account) async throws -> Account {
        let body = try JSONSerialization.data(withJSONObject: [
            "name": account.name, "balance": account.balance
        ])
        let (data, resp) = try await request(
            path: "accounts/", method: "POST", body: body, authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(Account.self, from: data)
    }

    func updateAccount(_ account: Account) async throws -> Account {
        let body = try JSONSerialization.data(withJSONObject: [
            "name": account.name, "balance": account.balance
        ])
        let (data, resp) = try await request(
            path: "accounts/\(account.id)/", method: "PUT",
            body: body, authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(Account.self, from: data)
    }

    // MARK: – Transactions
    func fetchTransactions() async throws -> [Transaction] {
        let (data, resp) = try await request(path: "transactions/", authenticated: true)
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }

        do {
            return try decoder.decode([Transaction].self, from: data)
        } catch {
            // 👇 розширений лог
            print("RAW transactions JSON:\n", String(data: data, encoding: .utf8) ?? "<nil>")
            print("DECODE error:", error)
            throw error   // щоб побачити той самий алерт
        }
    }

    func createTransaction(_ tx: Transaction) async throws -> Transaction {
        let iso = ISO8601DateFormatter().string(from: tx.date)
        let body = try JSONSerialization.data(withJSONObject: [
            "account": tx.account, "type": tx.type, "amount": tx.amount,
            "category": tx.category, "description": tx.description, "date": iso
        ])
        let (data, resp) = try await request(
            path: "transactions/", method: "POST",
            body: body, authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(Transaction.self, from: data)
    }

    func updateTransaction(_ tx: Transaction) async throws -> Transaction {
        let iso = ISO8601DateFormatter().string(from: tx.date)
        let body = try JSONSerialization.data(withJSONObject: [
            "account": tx.account, "type": tx.type, "amount": tx.amount,
            "category": tx.category, "description": tx.description, "date": iso
        ])
        let (data, resp) = try await request(
            path: "transactions/\(tx.id)/", method: "PUT",
            body: body, authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
        return try decoder.decode(Transaction.self, from: data)
    }

    func deleteTransaction(id: Int) async throws {
        let (_, resp) = try await request(
            path: "transactions/\(id)/", method: "DELETE", authenticated: true
        )
        guard (200..<300).contains(resp.statusCode) else {
            throw NetworkError.statusCode(resp.statusCode)
        }
    }

    // MARK: – Analytics (старий ендпоїнт)
    func fetchAnalytics() async throws -> AnalyticsResponse {
            let (data, resp) = try await request(path: "analytics/", authenticated: true)
            guard (200..<300).contains(resp.statusCode) else {
                throw NetworkError.statusCode(resp.statusCode)
            }
            print("📦 Raw analytics bytes:", data.count,
                  String(data: data, encoding: .utf8) ?? "<non-UTF8>")
            return try decode(AnalyticsResponse.self, from: data, label: "analytics")
    }


    // MARK: – Analytics Summary (новий ендпоїнт)
    ///   • period=this_month / this_week  **або**  start+end (YYYY-MM-DD)
    func fetchSummary(period: String? = "this_month",
                          start: Date? = nil,
                          end: Date? = nil) async throws -> SummaryResponse
        {
            // — складання URL
            var comps = URLComponents(url: APIConfig.baseURL, resolvingAgainstBaseURL: false)!
            comps.path += "/analytics/summary/"
            if let p = period {
                comps.queryItems = [ .init(name: "period", value: p) ]
            } else if let s = start, let e = end {
                let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]
                comps.queryItems = [
                    .init(name: "start", value: df.string(from: s)),
                    .init(name: "end",   value: df.string(from: e))
                ]
            }
            guard let url = comps.url else { throw NetworkError.badResponse }

            var req = URLRequest(url: url)
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            if let tok = accessToken {
                req.setValue("Bearer \(tok)", forHTTPHeaderField: "Authorization")
            }

            #if DEBUG
            print("▶️ GET \(url.absoluteString)")
            #endif

            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw NetworkError.statusCode((resp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            return try decode(SummaryResponse.self, from: data, label: "summary")
        }
    }
