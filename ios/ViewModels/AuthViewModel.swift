import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared
    private let keychain = KeychainManager.shared
    private var sessionObserver: NSObjectProtocol?

    init() {
        // Logged in if a Keychain access token exists
        isAuthenticated = keychain.getAccessToken() != nil
        sessionObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isAuthenticated = false }
        }
    }

    /// Logs in, stores tokens in Keychain, updates isAuthenticated
    func signIn(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let tokens = try await network.login(username: username, password: password)
            keychain.saveAccessToken(tokens.access)
            keychain.saveRefreshToken(tokens.refresh)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Registers; returns false and sets errorMessage on failure
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await network.register(username: username, email: email, password: password)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Logs out, clears tokens, updates isAuthenticated
    func signOut() async {
        isLoading = true
        if let refresh = keychain.getRefreshToken() {
            try? await network.logout(refresh: refresh)
        }
        keychain.deleteTokens()
        isAuthenticated = false
        isLoading = false
    }
}
