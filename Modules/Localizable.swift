//
//  Localizable.swift.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 22.08.25.
//

import Foundation

func Localizable(_ key: String) -> String {
    LocalizationManager.shared.localizedString(for: key)
}
