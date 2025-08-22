//
//  SwiftUI_TestApp.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 07.11.24.
//

import SwiftUI

@main
struct MyApp: App {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "German"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .frame(minWidth: 500, minHeight: 720)  // Set min width and height
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Optional: Versteckt den Fenstertitel
    }
}

