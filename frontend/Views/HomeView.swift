// Views/HomeView.swift

import SwiftUI

struct HomeView: View {
  var body: some View {
    TabView {
      AnalyticsView()
        .tabItem { Label("Analytics", systemImage: "chart.bar") }
      AccountsListView()
        .tabItem { Label("Accounts",  systemImage: "banknote") }
      TransactionsListView()
        .tabItem { Label("Transactions", systemImage: "list.bullet") }
      ProfileView()
        .tabItem { Label("Profile",   systemImage: "person.circle") }
    }
  }
}
