import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var userEmail: String = ""

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            if isLoggedIn {
                HomeView()
            } else {
                NavigationView {
                    VStack {
                        Spacer().frame(height: 120)

                        Text("BUDGET TRACKER")
                            .font(.custom("AbhayaLibre-ExtraBold", size: 47))
                            .foregroundColor(Color(red: 0.27, green: 0.20, blue: 0.18))

                        Text("WELCOME")
                            .font(.custom("AbhayaLibre-Medium", size: 36))
                            .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.5))
                            .padding(.bottom, 20)

                        Spacer().frame(height: 120)

                        NavigationLink(destination: RegisterView()) {
                            Text("Sign up")
                                .font(.custom("Inconsolata", size: 32))
                                .foregroundColor(.white)
                                .frame(width: 239, height: 63)
                                .background(Color(red: 0.27, green: 0.20, blue: 0.18))
                                .cornerRadius(20)
                        }
                        .padding(.bottom, 20)

                        Spacer()

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
                        .padding(.bottom, 30)
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
