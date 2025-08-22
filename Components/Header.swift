//
//  Header.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 21.08.25.
//

import SwiftUI

// Get the current username
var currentUserName: String {
    return NSFullUserName()
}

struct UserHeaderView: View {

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
            
            Divider().padding(.vertical, 10)
        }
    }
}
