import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome Back")
                    .font(.largeTitle).bold()
                    .padding(.top, 40)

                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if authVM.isLoading {
                    ProgressView().padding()
                }

                Button("Login") {
                    Task {
                        await authVM.signIn(
                            username: username,
                            password: password
                        )
                    }
                }
                .disabled(authVM.isLoading)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)

                if let err = authVM.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                NavigationLink("Don't have an account? Sign up") {
                    RegisterView()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Login")
        }
    }
}
