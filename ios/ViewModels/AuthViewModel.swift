import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared
    private let keychain = KeychainManager.shared

    init() {
        // Logged in if a Keychain access token exists
        isAuthenticated = keychain.getAccessToken() != nil
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

    /// Registers; surfaces the API message (success or error)
    func signUp(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await network.register(username: username,
                                                      email: email,
                                                      password: password)
            // Server returns message: String
            errorMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
