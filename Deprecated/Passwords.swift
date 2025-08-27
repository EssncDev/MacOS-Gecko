//
//  Passwords.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 07.07.25.
//
// Deprecated since 07/2025
// Same features now under "extras"


import SwiftUI

struct PasswordPage: View {

    var body: some View {
        VStack {
            // Headline and user
            Text("MacOSGecko")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.top, 10.0)
            Text("User: \(currentUserName)")
                .font(.subheadline)
                .fontWeight(.bold)
                .padding()
            
            Text("Export der Passwörter:\n1) Passwörter App Aufrufen über Button\n2) App mit Benutzerkennwort entsperren\n3) Menüleiste 'Ablage' 'Alle Passwörter in eine Datei exportieren'")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
            
            Button("Passwörter aufrufen") {
                // Öffne Passwort App via Terminal Pipeline
                TerminalClient.runCommandOpen("open -a passwords.app")
            }
            .background(Color.blue)
            .cornerRadius(30)
            .padding(10)
        }
    }
}
