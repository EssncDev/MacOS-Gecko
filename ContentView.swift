//
//  ContentView.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 07.11.24.
//

import SwiftUI

@available(macOS 14.0, *)
struct ContentView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "German"
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView {
            NotificationPage()
                .tabItem {
                    Label(Localizable("application_tab"), systemImage: "info")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
            
            LandingPage()
                .tabItem {
                    Label(Localizable("backup_tab"), systemImage: "opticaldiscdrive")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
            
            ExtraPage()
                .tabItem {
                    Label(Localizable("extra_tab"), systemImage: "opticaldiscdrive")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
            
            SettingsPage()
                .tabItem {
                    Label(Localizable("settings_tab"), systemImage: "info")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
        }
        .padding()
        .tabViewStyle(DefaultTabViewStyle())  // Optional: Der Default-TabView-Stil
                .padding(.top, 0)  // Kein Padding oben für die TabView
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: selectedLanguage) { _, newValue in
            localization.selectedLanguage = newValue
        }
        .frame(width: 375, height: 720)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
