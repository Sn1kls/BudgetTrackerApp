import SwiftUI

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var registrationError: String = ""
    @State private var isRegisteredAndLoggedIn = false
    @State private var userEmail: String = ""

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer().frame(height: 50)

                // Заголовок
                Text("Create an Account")
                    .font(.custom("AbhayaLibre-ExtraBold", size: 36))
                    .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))

                // Поле для Email
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)
                    .autocapitalization(.none)

                // Поле для Password
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)

                if !registrationError.isEmpty {
                    Text(registrationError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }

                // Кнопка "Register"
                Button(action: registerAndLoginUser) {
                    Text("Register")
                        .font(.custom("Inconsolata", size: 28))
                        .foregroundColor(.white)
                        .frame(width: 239, height: 63)
                        .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                        .cornerRadius(20)
                }
                .padding(.top, 10)

                Spacer()

                NavigationLink(destination: LoginView()) {
                    Text("Already have an account? Login")
                        .font(.custom("Inconsolata", size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(isRegisteredAndLoggedIn)
            .background(
                NavigationLink(
                    destination: HomeView(userEmail: userEmail),
                    isActive: $isRegisteredAndLoggedIn
                ) { EmptyView() }
            )
        }
    }

    private func registerAndLoginUser() {
        do {
            // Реєстрація нового користувача
            try DatabaseManager.shared.insertUser(email: email, password: password)

            // Пошук користувача після реєстрації
            if let user = try DatabaseManager.shared.authenticateUser(email: email, password: password) {
                UserDefaults.standard.set(user.id, forKey: "loggedInUserID")
                userEmail = user.email
                isRegisteredAndLoggedIn = true // Переходимо на HomeView
            } else {
                registrationError = "Registration successful, but login failed."
            }
        } catch {
            registrationError = "Failed to register. Email may already be used."
        }
    }
}
