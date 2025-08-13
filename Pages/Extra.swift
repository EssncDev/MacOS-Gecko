//
//  Extra.swift
//  MacOSGecko
//
//  Created by DF-Augsburg on 25.07.25.
//

import SwiftUI
import AppKit

struct ExtraPage: View {
    
    // State Declaration
    @State public var lineThikness = 10.0
    @State public var vstackTextPadding = 25.0
    @State private var isProcessing = false
    @State private var popupMessage = "Starting..."
    
    /// Opens a file picker dialog to allow the user to select a folder, then starts the DMG creation process for the selected folder.
    ///
    /// This function presents a dialog (using `NSOpenPanel`) that allows the user to choose a directory.
    /// Once a directory is selected, it calls the `startDMGCreation(at:)` function asynchronously to create a DMG file
    /// for the selected folder.
    ///
    /// - Note: Only a single folder can be selected, and the function will process the first folder selected by the user.
    func createDMG() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Ordner auswählen"
        openPanel.prompt = "Auswählen"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let selectedURL = openPanel.urls.first {
            Task {
                await startDMGCreation(at: selectedURL)
            }
        }
    }
    
    /// Opens a file picker dialog to allow the user to select a folder, then exports the device information to the selected folder.
    ///
    /// This function presents a dialog (using `NSOpenPanel`) that allows the user to choose a directory.
    /// Once a directory is selected, it calls the `exportMacInfo(at:)` function asynchronously to export the device's
    /// information (such as system logs) to the chosen folder.
    ///
    /// - Note: Only a single folder can be selected, and the function will process the first folder selected by the user.
    func exportDeviceInfo() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Ordner auswählen"
        openPanel.prompt = "Auswählen"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
    
        if openPanel.runModal() == .OK, let selectedURL = openPanel.urls.first {
            Task {
                await exportMacInfo(at: selectedURL)
            }
        }
    }
    
    /// Starts the creation of a DMG file and displays a processing popup with status updates.
    ///
    /// This function begins the process of creating a DMG file at the specified URL. It updates the popup message
    /// to inform the user about the ongoing process. Once the DMG file is successfully created, the popup message is
    /// updated to indicate success. After a brief delay, the popup is hidden.
    ///
    /// - Parameters:
    ///   - url: The URL where the DMG file will be saved.
    ///
    /// - Note: The `isProcessing` flag is set to true during the process and is set to false after the popup is hidden.
    ///         The popup message is updated to reflect the current status at each step of the process.
    func startDMGCreation(at url: URL) async {
        isProcessing = true
        popupMessage = "Erstelle DMG..."
        
        do {
            await CopyClient().createDMG(targetUrl: url)
            // update popup message
            await MainActor.run {
                popupMessage = "DMG erstellt!"
            }
        }
        
        // hide popup nach X Sekunden
        await Task.sleep(3 * 1_000_000_000)
        await MainActor.run {isProcessing = false}
    }
    
    /// Creates a device log file and displays a processing popup with status updates.
    ///
    /// This function initiates the creation of a device log file at the specified URL and updates the UI with
    /// a popup message to inform the user about the status. Once the file is created, the popup message is updated
    /// to indicate that the file has been successfully created. After a brief delay, the popup is hidden.
    ///
    /// - Parameters:
    ///   - url: The URL where the device log file will be saved.
    ///
    /// - Note: The `isProcessing` flag is set to true while the process is ongoing and is set to false after
    ///         the popup is hidden. The popup message is updated to reflect the current status during the process.
    func exportMacInfo(at url: URL) async {
        isProcessing = true
        popupMessage = "Erstelle Datei"
        
        do {
            FileLogger.createDeviceLog(targetPath: url, userName: currentUserName)
            // update popup message
            await MainActor.run {
                popupMessage = "Datei erstellt!"
            }
        }
        
        // hide popup nach X Sekunden
        await Task.sleep(3 * 1_000_000_000)
        await MainActor.run {isProcessing = false}
    }
    
    /// Opens a file picker dialog to allow the user to select a folder, then starts hashing the contents of the selected folder.
    ///
    /// This function presents a dialog (using `NSOpenPanel`) that allows the user to choose a directory.
    /// Once the directory is selected, it calls the `startHashData(at:)` function asynchronously to begin hashing the files
    /// in the selected directory.
    ///
    /// - Note: The function only allows the selection of directories and does not support multiple selections.
    ///         It will process the first selected folder and initiate hashing asynchronously.
    func hashData() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Ordner auswählen"
        openPanel.prompt = "Auswählen"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let selectedURL = openPanel.urls.first {
            Task {
                await startHashData(at: selectedURL)
            }
        }
    }
    
    /// Calculates and logs the MD5 hash for each file within a specified folder.
    ///
    /// This function uses the `find` command to recursively search for all files (`-type f`)
    /// within the specified folder and its subfolders. For each file, it calculates the MD5 hash
    /// using the `md5` command and logs the results to a specified log file.
    ///
    /// The function operates asynchronously and waits for the task to finish before processing
    /// the results. Each file’s MD5 hash and its path are written to the provided log file.
    ///
    /// - Parameters:
    ///   - url: The URL of the folder whose files are to be hashed.
    ///   - logFileURL: The URL of the log file where the hash results will be appended.
    ///
    /// - Note:
    ///   This function does not filter out temporary or hidden files. All files found by `find`
    ///   are processed, including those in subdirectories and any hidden files.
    func hashFolder(at url: URL, logFileURL: URL) async {
        let task = Process()
        task.launchPath = "/usr/bin/find"
        task.arguments = [url.path, "-type", "f", "-exec", "md5", "{}", ";"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            if let output = String(data: data, encoding: .utf8) {
                let lines = output.split(whereSeparator: \.isNewline)
                for line in lines {
                    if line.isEmpty { continue }

                    let components = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                    if components.count > 1 {
                        let hash = components[0]
                        let filePath = components[1]
                        FileLogger.appendToLog(logFileURL: logFileURL, message: "MD5 Hash for \(filePath): \(hash)")
                    }
                }
            }
        }
    }
    
    func startHashData(at url: URL) async {
        isProcessing = true
        popupMessage = "Hashe Datei"
        
        do {
            await hashFile(at: url)
            // update  popup message
            await MainActor.run {
                popupMessage = "Fertiggestellt!"
            }
        }
        
        // hide popup nach X Sekunden
        await Task.sleep(2 * 1_000_000_000)
        await MainActor.run {isProcessing = false}
    }

    func hashFile(at url: URL) async {
        let targetRootURL = url.deletingLastPathComponent()
        let logFileURL = targetRootURL.appendingPathComponent("hashing_log.txt")
        
        // check if Log-File exists
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        // initiate content header with timestamp
        let logContent = """
        Hash log
        -----------------
        Date: \(FileLogger.createCurrentTimeStamp())
        -----------------\n
        """
        FileLogger.appendToLog(logFileURL: logFileURL, message: logContent)
        
        // check if current object is a folder
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            FileLogger.appendToLog(logFileURL: logFileURL, message: "Hashing Path: \(url.path)")
            await hashFolder(at: url, logFileURL: logFileURL)
        } else {
            // Log error(s)
            FileLogger.appendToLog(logFileURL: logFileURL, message: "Invalid file or folder path: \(url.path)")
        }
    }
    
    func openPasswords() {
        TerminalClient.runCommandOpen("open -a passwords.app")
    }

    var body: some View {
        VStack {
            // Headline und User
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
            
            List {
                VStack(alignment: .leading){
                    Button(action: createDMG) {
                        HStack {
                            Text("Erstelle DMG von Ordner")
                            Spacer()
                        }
                    }
                    .padding(.vertical, CGFloat(lineThikness))
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()  // Set hand cursor
                        } else {
                            NSCursor.arrow.set()  // Reset to default
                        }
                    }
                    
                    Text("Erstellt einen Container aus ausgewähltem Ordner inkl. Unterordnern")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, CGFloat(vstackTextPadding))
                }
                
                VStack(alignment: .leading){
                    Button(action: hashData) {
                        HStack {
                            Text("Ordner hashen")
                            Spacer()
                        }
                    }
                    .padding(.vertical, CGFloat(lineThikness))
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()  // Set hand cursor
                        } else {
                            NSCursor.arrow.set()  // Reset to default
                        }
                    }
                    
                    Text("Erstellt eine Prüfsumme aus ausgewähltem Ordner")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, CGFloat(vstackTextPadding))
                }
                
                VStack(alignment: .leading){
                    Button(action: exportDeviceInfo) {
                        HStack {
                            Text("Geräteinformationen exportieren")
                            Spacer()
                        }
                    }
                    .padding(.vertical, CGFloat(lineThikness))
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()  // Set hand cursor
                        } else {
                            NSCursor.arrow.set()  // Reset to default
                        }
                    }
                    
                    Text("Exportiert die Geräteinformationen inkl. Datenträgereigenschaften in eine Textdatei")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, CGFloat(vstackTextPadding))
                }
                
                VStack(alignment: .leading){
                    Button(action: openPasswords) {
                        HStack {
                            Text("Passwörter öffnen")
                            Spacer()
                        }
                    }
                    .padding(.vertical, CGFloat(lineThikness))
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()  // Set hand cursor
                        } else {
                            NSCursor.arrow.set()  // Reset to default
                        }
                    }
                    
                    Text("Export der Passwörter:\n1) Passwörter-App aufrufen über Button\n2) App mit Benutzerkennwort entsperren\n3) Menüleiste 'Ablage' 'Alle Passwörter in eine Datei exportieren'")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, CGFloat(vstackTextPadding))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .overlay(
            Group {
                if isProcessing {
                    VStack {
                        Text(popupMessage)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.25))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isProcessing)
                }
            }
        )
    }
}
