import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var userEmail: String = ""

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // Білий фон на весь екран

            if isLoggedIn {
                HomeView(userEmail: userEmail)
            } else {
                NavigationView {
                    VStack {
                        Spacer().frame(height: 120) // Менший відступ перед заголовком

                        // Заголовок
                        Text("BUDGET TRACKER")
                            .font(.custom("AbhayaLibre-ExtraBold", size: 47))
                            .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18)) // Темно-коричневий

                        // Підзаголовок
                        Text("WELCOME")
                            .font(.custom("AbhayaLibre-Medium", size: 36))
                            .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.5)) // Підзаголовок світліший
                            .padding(.bottom, 20)

                        Spacer().frame(height: 120) // Підняти кнопку вище

                        // Кнопка "Sign Up"
                        NavigationLink(destination: RegisterView()) {
                            Text("Sign up")
                                .font(.custom("Inconsolata", size: 32))
                                .foregroundColor(.white)
                                .frame(width: 239, height: 63)
                                .background(Color(red: 0.27, green: 0.20, blue: 0.18)) // Темно-коричневий
                                .cornerRadius(20)
                        }
                        .padding(.bottom, 20)

                        Spacer()

                        // Текст "Do you have an account?"
                        HStack {
                            Text("Do you have an account?")
                                .font(.custom("Inconsolata", size: 18))
                                .foregroundColor(.gray)

                            NavigationLink(destination: LoginView()) {
                                Text("Login")
                                    .font(.custom("Inconsolata", size: 18))
                                    .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))
                                    .bold()
                            }
                        }
                        .padding(.bottom, 30) // Відступ знизу
                    }
                }
            }
        }
        .onAppear {
            checkSession()
        }
    }

    private func checkSession() {
        if let userID = UserDefaults.standard.value(forKey: "loggedInUserID") as? Int64 {
            do {
                if let user = try DatabaseManager.shared.fetchUserByID(userID: userID) {
                    userEmail = user.email
                    isLoggedIn = true
                }
            } catch {
                print("Failed to fetch user: \(error)")
            }
        }
    }
}
