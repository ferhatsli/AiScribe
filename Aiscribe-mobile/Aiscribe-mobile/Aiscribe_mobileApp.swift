//
//  Aiscribe_mobileApp.swift
//  Aiscribe-mobile
//
//  Created by Ferhat Taşlı on 7.05.2025.
//

import SwiftUI

@main
struct Aiscribe_mobileApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var imageViewModel = ImageViewModel()
    @StateObject private var resultViewModel = ResultViewModel()
    @State private var showSplash = true
    @State private var isTokenValidated = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Splash Screen
                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                } else {
                    // Main App Content
                    Group {
                        if authViewModel.isAuthenticated {
                            ContentView()
                                .environmentObject(themeManager)
                                .environmentObject(authViewModel)
                                .environmentObject(imageViewModel)
                                .environmentObject(resultViewModel)
                                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                                .onAppear {
                                    setupViewModels()
                                }
                        } else {
                            LoginView()
                                .environmentObject(themeManager)
                                .environmentObject(authViewModel)
                                .environmentObject(imageViewModel)
                                .environmentObject(resultViewModel)
                                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Uygulama arka plandan tekrar öne geldiğinde
                showSplash = true
                
                // Splash ekranı bittikten sonra token kontrolü yapsın
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    authViewModel.refreshUserSession()
                }
            }
        }
    }
    
    // View modelleri kurma işlemini bir fonksiyona taşıyalım
    private func setupViewModels() {
        // AuthViewModel'i ImageViewModel'e bağla
        imageViewModel.authViewModel = authViewModel
        // Kullanıcıya ait görselleri yükle
        imageViewModel.refreshImages()
        
        // AuthViewModel'i ResultViewModel'e bağla
        resultViewModel.authViewModel = authViewModel
        // Kullanıcıya ait promptları yükle
        resultViewModel.refreshResults()
    }
}
