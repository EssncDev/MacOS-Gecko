//
//  Sicherung.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 11.11.24.
//

import SwiftUI
import AppKit

struct LandingPage: View {
    @State private var selectedItems: [String: Bool] = [
        "Dokumente": true,
        "Downloads": true,
        "Schreibtisch": true,
        "Öffentlich": false,
        "Musik": false,
        "Filme": false,
        "Bilder": false
    ]
    
    @State public var isCopying: Bool = false // state if copying is in progress or not
    @State public var finishedTask: Bool = false // state if copying is finished
    @State public var progress = 0.0 // progress of copying
    @State public var progressMessage = ""
    @State public var progressMessagePath = ""
    @State public var progressCount = 0
    @State public var folderCountMax = 7
    @State private var containerCreation : Bool = true
    
    // Base path for user directories
    let userDirectory = FileManager.default.homeDirectoryForCurrentUser
    // Get the current username
    var currentUserName: String {
        return NSFullUserName()
    }
    // State variable for target path
    @State private var targetPath: String = "Kein Ort ausgewählt"

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
            
            // List of directories
            List {
                Text("Auswahl der zu kopierenden Verzeichnisse")
                ForEach(selectedItems.keys.sorted(), id: \.self) { key in
                    if let isSelected = selectedItems[key] {
                        
                        HStack {
                            Toggle(isOn: Binding(
                                get: { isSelected },
                                set: { selectedItems[key] = $0 }
                            )) {
                                Text(key)
                                    .multilineTextAlignment(.leading)
                                    .padding(.leading, 5.0)
                            }
                        }
                    }
                }
            }
            .frame(height: CGFloat(30 * folderCountMax))
            
            // Status info text
            Text("\(selectedCount()) Verzeichnis\(selectedCount() == 1 ? "" : "se") ausgewählt")
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.vertical, 2.5)
                .font(.headline)
                .foregroundColor(.blue)
            
            // Target folder selection
            HStack {
                Text("Zielpfad wählen:")
                    .font(.headline)
                
                Button(action: selectTargetFolder) {
                    HStack {
                        Image(systemName: "folder")
                        Text(targetPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(5)
                    .cornerRadius(8)
                }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()  // Set hand cursor
                    } else {
                        NSCursor.arrow.set()  // Reset to default
                    }
                }
            }
            .padding()
                
            // Create DMG + MD5 selection
            VStack {
                Toggle("DMG-Container und MD5-Hash erstellen:", isOn: $containerCreation)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                Text("Das zusätzliche Erstellen eines Containers benötigt die doppelte Menge an Speicherplatz!\n")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .padding()
             
            // Buttons
            HStack {
                Button(action: {
                    selectAll()
                }) {
                    if selectedCount() != folderCountMax {
                        Text("Alle auswählen")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    } else {
                        Text("Alle abwählen")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()  // Set hand cursor
                    } else {
                        NSCursor.arrow.set()  // Reset to default
                    }
                }
                
                Button(action: {
                    Task {
                        await startCopy()
                    }
                    isCopying = true
                }) {
                    Text("Vorgang starten")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isCopyButtonEnabled || isCopying)
                .padding()
                .onHover { hovering in
                    if hovering && isCopyButtonEnabled {
                        NSCursor.pointingHand.set()  // Set hand cursor
                    } else {
                        NSCursor.arrow.set()  // Reset to default
                    }
                }
            }
            .padding(.bottom, 10.0)
            
            if isCopying {
                VStack{
                    Text("\(progressMessage)")
                        .font(.body)
                    Text("\(progressMessagePath)")
                        .font(.body)
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 30.0)
                }
                .padding(.bottom, 50.0)
            }
                
            if finishedTask {
                Text("Fertiggestellt!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .frame(alignment: .top)
    }

    // Function to return a description based on the directory name
    private func getDescription(for key: String) -> String {
        switch key {
        case "Dokumente":
            return "Alle Dateien und Ordner in Dokumente"
        case "Downloads":
            return "Alle Dateien und Ordner in Downloads"
        case "Schreibtisch":
            return "Alle Dateien und Ordner des Schreibtisches"
        case "Musik":
            return "Gesamten Ordner 'Musik'"
        case "Öffentlich":
            return "Gesamten Ordner 'Öffentlich'"
        case "Bilder":
            return "Gesamten Ordner 'Bilder'"
        case "Filme":
            return "Gesamten Ordner 'Filme'"
        default:
            return ""
        }
    }

    // Function to count selected directories
    private func selectedCount() -> Int {
        return selectedItems.filter { $0.value }.count
    }

    // Selecting target folder
    private func selectTargetFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
      
        openPanel.beginSheetModal(for: NSApplication.shared.mainWindow!) { response in
            if response == .OK {
                if let url = openPanel.url {
                    DispatchQueue.main.async {
                        self.targetPath = url.path
                    }
                }
            }
        }
    }

    // Function to select or deselect all items
    private func selectAll() {
        let allSelected = !selectedItems.values.allSatisfy { $0 }
        for key in selectedItems.keys {
            selectedItems[key] = allSelected
        }
    }

    // Computed property to determine if the copy button should be enabled
    private var isCopyButtonEnabled: Bool {
        return selectedCount() > 0 && targetPath != "Kein Ort ausgewählt"
    }
    
    // Switch Function
    public func SwitchFolderNames(folderName: String) -> String {
        switch folderName {
        case "Dokumente":
            return "Documents"
        case "Downloads":
            return "Downloads"
        case "Schreibtisch":
            return "Desktop"
        case "Musik":
            return "Music"
        case "Öffentlich":
            return "Public"
        case "Bilder":
            return "Pictures"
        case "Filme":
            return "Movies"
        default:
            return ""
        }
    }
    
    // Asynchronous function to start copying
    public func startCopy() async {
        let selectedKeys = selectedItems.filter { $0.value }.map { $0.key }
        var selectedPaths: [URL] = []
        for key in selectedKeys {
            selectedPaths.append(userDirectory.appendingPathComponent(SwitchFolderNames(folderName: key)))
        }
        let folderPath = targetPath + "/Sicherung"
        // Check if the folder already exists
        TerminalClient.runCommandOpen("mkdir -p \(folderPath)")

        // Convert targetPath to URL
        let targetURL = URL(fileURLWithPath: folderPath)
        let targetRootURL = targetURL.deletingLastPathComponent()
        
        // Create log file
        guard let logFileURL = FileLogger.createCopyLog(
            sourcePaths: selectedPaths,
            targetPath: targetRootURL,
            userName: currentUserName
        ) else {
            print("Failed to create log file.")
            return
        }
        
        FileLogger.createDeviceLog(
            targetPath: targetRootURL,
            userName: currentUserName
        )
        
        FileLogger.appendToLog(
            logFileURL: logFileURL,
            message: "\(FileLogger.createCurrentTimeStamp()) | Device Log created"
        )
        
        guard let errorLogFile = FileLogger.createErrorLog(
            targetPath: targetRootURL,
            userName: currentUserName
        ) else {
            print("Failed to create error log file.")
            return
        }
        
        FileLogger.appendToLog(
            logFileURL: logFileURL,
            message: "\(FileLogger.createCurrentTimeStamp()) | Error Log created \n"
        )
        
        // Perform the copy operations asynchronously
        for path in selectedPaths {
            progressMessagePath = "Current Path: \(path.absoluteString)"
            let lastSourceComponent = path.lastPathComponent
            
            // create root folder for each dir
            let newTargetUrl = targetURL.appendingPathComponent(lastSourceComponent)
            do {
                try FileManager.default.createDirectory(at: newTargetUrl, withIntermediateDirectories: true, attributes: nil)
                
                FileLogger.appendToLog(
                    logFileURL: logFileURL,
                    message: "\n\nCreated Root Folder: \(lastSourceComponent)"
                )
            }
            catch
                {
                print("Failed to create root folder for \(path.absoluteString)")
            }
            
            CopyClient().copyFiles(sourcePath: path, targetPath: newTargetUrl, statusLog: logFileURL, errorLog: errorLogFile)
            
            progressCount += 1
            progress = Double(progressCount) / Double(selectedPaths.count + 2)
            
            let percentage = (progress * 100).rounded()
            progressMessage = "\(Int(percentage))%"
        }
        
        if (containerCreation) {
            // Create DMG
            progressMessagePath = "Erstelle DMG"
            await CopyClient().createDMG(targetUrl: targetURL)
            progressCount += 1
            progress = Double(progressCount) / Double(selectedPaths.count + 2)
            progressMessage = "\(Int((progress * 100).rounded()))%"
            
            // Hash MD5 DMG
            progressMessagePath = "Erstelle MD5 Hash"
            let dmgName = targetURL.lastPathComponent
            let finalTargetPath = targetURL.deletingLastPathComponent()
            let dmgUrl = finalTargetPath.appendingPathComponent("\(dmgName).dmg")
            
            let md5Hash = await CopyClient().md5OfDMG(dmgUrl: dmgUrl)
            progressCount += 1
            progress = Double(progressCount) / Double(selectedPaths.count + 2)
            progressMessage = "\(Int((progress * 100).rounded()))%"
            
            FileLogger.appendToLog(logFileURL: logFileURL, message: """
            \n\n
            MD5 Hash Log
            -----------------
            Date: \(FileLogger.createCurrentTimeStamp())
            -----------------\n
            DMG Name: \(dmgName)
            Hash: \(md5Hash ?? "Fehler")\n
            """)
        }
        
        // Update states after copying is complete
        isCopying = false
        finishedTask = true
        selectedItems = [
            "Dokumente": false,
            "Downloads": false,
            "Schreibtisch": false,
            "Öffentlich": false,
            "Musik": false,
            "Filme": false,
            "Bilder": false,
            "Papierkorb": false
        ]
        progress = 0.0
        progressCount = 0
    }
}

struct LandingPage_Previews: PreviewProvider {
    static var previews: some View {
        LandingPage()
    }
}
