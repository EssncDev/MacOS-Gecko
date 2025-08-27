//
//  Applikations.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 12.11.24.
//

import SwiftUI

// Base Path for user home dir
let userDirectory = FileManager.default.homeDirectoryForCurrentUser

@available(macOS 14.0, *)
struct NotificationPage: View {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "German"
    @ObservedObject private var localization = LocalizationManager.shared
    
    @State private var applicationList = ""
    @State private var filteredApps: [String] = []
    @State private var searchButtonHide: Bool = false;
    
    // List of relevant Apps
    private let appsToFilter = [
        "Parallels Desktop.app",
        "Dropbox.app",
        "WhatsApp.app",
        "OneDrive.app",
        "Microsoft Outlook.app",
        "Mail.app"
    ]
    
    func prepareAppLibURL(appName: String) -> URL {
        switch appName {
        case "Dropbox.app":
            return userDirectory.appendingPathComponent("Library").appendingPathComponent("Dropbox")
        case "Parallels Desktop.app":
            return userDirectory.appendingPathComponent("Library").appendingPathComponent("Parallels")
        case "Mail.app":
            return userDirectory.appendingPathComponent("Library").appendingPathComponent("Mail")
        default:
            return userDirectory.appendingPathComponent("Library")
        }
    }
    
    var body: some View {
        VStack {
            // Headline and user
            UserHeaderView()
            
            Spacer()
            
            Text(Localizable("app_search_up_desc"))
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
            
            if !searchButtonHide {
                Button(Localizable("button_search_up_applications")) {
                    // Fetch the application list and filter it
                    applicationList = fetchApplicationList()
                    filteredApps = filterApplicationList(applicationList, filterTerms: appsToFilter)
                    searchButtonHide = true
                }
                .background(Color.blue)
                .cornerRadius(30)
                .padding(30) // Add padding around the button
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()  // Set hand cursor
                    } else {
                        NSCursor.arrow.set()  // Reset to default
                    }
                }
            }
            Spacer()
            
            // Display the filtered application list if it's not empty
            if !filteredApps.isEmpty {
                ScrollView {
                    // Use ScrollView to allow scrolling if there are many apps
                    VStack(alignment: .leading) {
                        ForEach(filteredApps, id: \.self) { app in
                            let charLenght = app.count
                            HStack {
                                HStack{
                                    Text("\(app.prefix(charLenght - 4))")
                                        .padding(15)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading) // Make each Text view expand to full width
                                .background(Color.gray.opacity(0.1)) // Optional: Add a background color for better visibility
                                .cornerRadius(5) // Optional: Add corner radius
                                
                                // App open button
                                Button(action: {
                                    TerminalClient.runCommandOpen("open -a \"\(app)\"")
                                }) {
                                    Text(Localizable("button_open_app"))
                                }.foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.0))
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.set()  // Set hand cursor
                                        } else {
                                            NSCursor.arrow.set()  // Reset to default
                                        }
                                    }
                                
                                // Öffne App Dir in Finder
                                Button(action: {
                                    let appUrl = prepareAppLibURL(appName: app)
                                    TerminalClient.runCommandOpen("open \"\(appUrl)\"")
                                }) {
                                    Text(Localizable("button_open_folder"))
                                }.foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.0))
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.set()  // Set hand cursor
                                        } else {
                                            NSCursor.arrow.set()  // Reset to default
                                        }
                                    }
                                
                            }
                            .padding(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .onChange(of: selectedLanguage) { _, newValue in
            localization.selectedLanguage = newValue
        }
    }
}

/// Fetches a list of installed and native applications on the system.
///
/// This function retrieves a list of applications installed on the system by running two terminal commands:
/// one to list the applications in `/Applications` (for user-installed apps) and another to list the applications
/// in `/System/Applications` (for system and native apps). It returns the combined list of application names.
///
/// - Returns: A string containing the names of installed applications, separated by newlines.
///
/// - Note: The returned list includes both user-installed and system-installed applications.
func fetchApplicationList() -> String {
    // get both installed and native Application list
    var appList = TerminalClient.runCommand("ls /Applications")
    appList += TerminalClient.runCommand("ls /System/Applications")
    return appList
}

/// Filters a list of application names based on the provided filter terms.
///
/// This function takes a string `appList`, which contains application names separated by newlines, and filters the list
/// based on the provided `filterTerms`. It returns an array of application names that match any of the filter terms.
///
/// - Parameters:
///   - appList: A string containing application names separated by newlines, where each line represents one application.
///   - filterTerms: An array of strings representing the filter terms to match against the application names.
///
/// - Returns: An array of strings containing the names of the applications that match the filter terms.
///
/// - Note: The function performs a case-sensitive search. If an application name contains any of the filter terms,
///         it will be included in the result.
func filterApplicationList(_ appList: String, filterTerms: [String]) -> [String] {
    // Split the appList into an array of application names
    let applications = appList.split(separator: "\n").map(String.init)
    // Filter the array for the specific search terms
    let filteredApplications = applications.filter { app in
        filterTerms.contains(where: { app.contains($0) })
    }
    return filteredApplications
}

struct NotificationPage_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPage()
    }
}
