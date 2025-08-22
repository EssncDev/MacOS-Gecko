//
//  Settings.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 21.08.25.
//

import SwiftUI

struct SettingsPage: View {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "German"
    @ObservedObject private var localization = LocalizationManager.shared
    
    let languages = ["English", "German"]
    
    var body: some View {
        VStack {
            // Headline and user
            UserHeaderView()
            
            // Appearance
            HStack{
                Section(header: Text("Dark Mode").font(.headline)) {
                    Spacer()
                    Toggle(isOn: $isDarkMode) {}
                    .toggleStyle(SwitchToggleStyle())
                }
            }
            .frame(width: 350)
            
            // Language Selection
            HStack{
                Section(header: Text("Language").font(.headline)) {
                    Spacer()
                    Picker("",selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
            }
            .frame(width: 350)
            
            Divider().padding(.vertical, 10)
            
            // Impressum / Contact Info
            Section(header: Text("Impressum").font(.headline)) {
                
                VStack(alignment: .center) {
                    Text("©2025 EssncDev")
                    Link("GitHub", destination: URL(string: "https://github.com/EssncDev")!)
                }
                .font(.subheadline)
                .padding(.top, 10)
            }
            Spacer()
        }
        .frame(alignment: .topLeading)
        .onChange(of: selectedLanguage) { _, newValue in
            localization.selectedLanguage = newValue
        }
    }
}
