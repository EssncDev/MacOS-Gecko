//
//  LocalizationsManager.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 22.08.25.
//

import Foundation

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var selectedLanguage: String {
        didSet {
            setLanguage(selectedLanguage)
        }
    }

    private(set) var bundle: Bundle = .main

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "English"
        self.selectedLanguage = saved
        setLanguage(saved)
    }

    private func setLanguage(_ language: String) {
        let code = mapLanguageToCode(language)
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            self.bundle = langBundle
        } else {
            self.bundle = .main
        }
    }

    private func mapLanguageToCode(_ language: String) -> String {
        switch language {
            case "German": return "de"
            case "English": return "en"
            default: return "en"
        }
    }

    func localizedString(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
