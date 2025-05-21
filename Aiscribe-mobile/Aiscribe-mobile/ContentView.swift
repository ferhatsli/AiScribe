//
//  ContentView.swift
//  Aiscribe-mobile
//
//  Created by Ferhat Taşlı on 7.05.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
                .tag(0)
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
