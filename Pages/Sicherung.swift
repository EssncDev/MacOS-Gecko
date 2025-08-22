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
        "Documents": true,
        "Downloads": true,
        "Desktop": true,
        "Public": false,
        "Music": false,
        "Movies": false,
        "Pictures": false
    ]
    
    @State public var isCopying: Bool = false // state if copying is in progress or not
    @State public var finishedTask: Bool = false // state if copying is finished
    @State public var progress = 0.0 // progress of copying
    @State public var progressMessage = ""
    @State public var progressMessagePath = ""
    @State public var progressCount = 0
    @State public var folderCountMax = 7
    @State private var containerCreation : Bool = true
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "German"
    @ObservedObject private var localization = LocalizationManager.shared
    
    // Base path for user directories
    let userDirectory = FileManager.default.homeDirectoryForCurrentUser
    // Get the current username
    var currentUserName: String {
        return NSFullUserName()
    }
    // State variable for target path
    @State private var targetPath: String = Localizable("path_desc")
    @State private var targetPathIsSet: Bool = false

    var body: some View {
        VStack {
            UserHeaderView()
            
            Spacer()
            
            // List of directories
            List {
                Text(Localizable("directory_list_selected"))
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
            Text(Localizable("selected_dir_amount") + ": \(selectedCount())")
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.vertical, 2.5)
                .font(.headline)
                .foregroundColor(.blue)
            
            // Target folder selection
            HStack {
                Text(Localizable("target_path_select"))
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
                Toggle(Localizable("dmg_container_toggle_desc"), isOn: $containerCreation)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                Text(Localizable("dmg_container_info"))
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
                        Text(Localizable("select_all_elements"))
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    } else {
                        Text(Localizable("unselect_all_elements"))
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
                    Text(Localizable("process_start"))
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
                Text(Localizable("finished_task") + "!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .frame(alignment: .top)
        .onChange(of: selectedLanguage) { _, newValue in
            localization.selectedLanguage = newValue
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
                        targetPathIsSet = true
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
        return selectedCount() > 0 && targetPathIsSet != false
    }
    
    // Asynchronous function to start copying
    public func startCopy() async {
        let selectedKeys = selectedItems.filter { $0.value }.map { $0.key }
        var selectedPaths: [URL] = []
        for key in selectedKeys {
            selectedPaths.append(userDirectory.appendingPathComponent(key))
        }
        let folderPath = targetPath + "/Sicherung"
        // Check if the folder already exists
        TerminalClient.runCommandOpen("mkdir -p \(folderPath)")

        // Convert targetPath to URL
        let targetURL = URL(fileURLWithPath: folderPath)
        let targetRootURL = targetURL.deletingLastPathComponent()
        
        guard let errorLogFile = FileLogger.createErrorLog(
            targetPath: targetRootURL,
            userName: currentUserName
        ) else {
            print("Failed to create error log file.")
            return
        }
        
        // Create log file
        guard let logFileURL = FileLogger.createCopyLog(
            sourcePaths: selectedPaths,
            targetPath: targetRootURL,
            userName: currentUserName
        ) else {
            FileLogger.appendToLog(logFileURL: errorLogFile, message: "Failed to create log file.")
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
                FileLogger.appendToLog(
                    logFileURL: errorLogFile,
                    message: "\nFailed to create Root Folder: \(lastSourceComponent)"
                )
            }
            
            CopyClient().copyFiles(sourcePath: path, targetPath: newTargetUrl, statusLog: logFileURL, errorLog: errorLogFile)
            
            progressCount += 1
            progress = Double(progressCount) / Double(selectedPaths.count + 2)
            
            let percentage = (progress * 100).rounded()
            progressMessage = "\(Int(percentage))%"
        }
        
        if (containerCreation) {
            // Create DMG
            progressMessagePath = Localizable("dmg_creation_step")
            await CopyClient().createDMG(targetUrl: targetURL)
            progressCount += 1
            progress = Double(progressCount) / Double(selectedPaths.count + 2)
            progressMessage = "\(Int((progress * 100).rounded()))%"
            
            // Hash MD5 DMG
            progressMessagePath = Localizable("md5_creation_step")
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
            Hash: \(md5Hash ?? "Error")\n
            """)
        }
        
        // Update states after copying is complete
        isCopying = false
        finishedTask = true
        selectedItems = [
            "Documents": false,
            "Downloads": false,
            "Desktop": false,
            "Public": false,
            "Music": false,
            "Movies": false,
            "Pictures": false
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
