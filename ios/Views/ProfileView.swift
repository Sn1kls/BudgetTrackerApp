import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Button("Sign Out") {
                    Task { await authVM.signOut() }
                }
                .foregroundColor(.red)
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}
