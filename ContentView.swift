//
//  ContentView.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 07.11.24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NotificationPage()
                .tabItem {
                    Label("Applikationen", systemImage: "info")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
            
            /*
             PasswordPage()
                .tabItem {
                    Label("Passwörter", systemImage: "opticaldiscdrive")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
             */
            
            LandingPage()
                .tabItem {
                    Label("Sicherung", systemImage: "opticaldiscdrive")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
            
            ExtraPage()
                .tabItem {
                    Label("Extra", systemImage: "opticaldiscdrive")
                        .font(.system(size: 18, weight: .bold))  // Adjust the font size and weight
                        .imageScale(.large)  // Make the icon larger
                }
        }
        .padding()
        .tabViewStyle(DefaultTabViewStyle())  // Optional: Der Default-TabView-Stil
                .padding(.top, 0)  // Kein Padding oben für die TabView
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
