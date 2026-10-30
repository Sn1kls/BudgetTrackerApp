import SwiftUI

struct RegisterView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle).bold()
                    .padding(.top, 40)

                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if authViewModel.isLoading {
                    ProgressView().padding()
                }

                Button("Register") {
                    Task {
                        if await authViewModel.signUp(username: username, email: email, password: password) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)

                if let message = authViewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}
