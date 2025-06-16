import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginError: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoggedIn = false
    @State private var userEmail: String = ""

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer().frame(height: 50)

                Text("Welcome Back")
                    .font(.custom("AbhayaLibre-ExtraBold", size: 36))
                    .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))

                TextField("Email", text: $email)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .frame(width: 300)

                if !loginError.isEmpty {
                    Text(loginError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }

                Button(action: loginUser) {
                    Text("Login")
                        .font(.custom("Inconsolata", size: 28))
                        .foregroundColor(.white)
                        .frame(width: 239, height: 63)
                        .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                        .cornerRadius(20)
                }
                .padding(.top, 10)

                Spacer()

                NavigationLink(destination: RegisterView()) {
                    Text("Don't have an account? Sign up")
                        .font(.custom("Inconsolata", size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(isLoggedIn)
            .background(
                NavigationLink(
                    destination: HomeView(userEmail: userEmail),
                    isActive: $isLoggedIn
                ) { EmptyView() }
            )
        }
    }

    private func loginUser() {
        do {
            if let user = try DatabaseManager.shared.authenticateUser(email: email, password: password) {
                UserDefaults.standard.set(user.id, forKey: "loggedInUserID")
                userEmail = user.email
                isLoggedIn = true
            } else {
                loginError = "Invalid email or password"
            }
        } catch {
            loginError = "An error occurred while logging in"
        }
    }
}
