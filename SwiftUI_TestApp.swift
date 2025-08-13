//
//  SwiftUI_TestApp.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 07.11.24.
//

import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .frame(minWidth: 500, minHeight: 720)  // Set min width and height
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Optional: Versteckt den Fenstertitel
    }
}

