import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared
    private let keychain = KeychainManager.shared

    init() {
        // Якщо в Keychain є access token — вважаємо користувача залогіненим
        isAuthenticated = keychain.getAccessToken() != nil
    }

    /// Логін: запитує токени, зберігає в Keychain, оновлює isAuthenticated
    func signIn(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let tokens = try await network.login(username: username, password: password)
            keychain.saveAccessToken(tokens.access)
            keychain.saveRefreshToken(tokens.refresh)
            isAuthenticated = true
        } catch {
            // можна деталізувати помилки за типом NetworkError та коду статусу
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Реєстрація: показує повідомлення з API (успіх/помилка)
    func signUp(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await network.register(username: username,
                                                      email: email,
                                                      password: password)
            // Сервер повертає message: String
            errorMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Вихід: відправляє logout, чистить токени, оновлює isAuthenticated
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
