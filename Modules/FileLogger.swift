//
//  Logger.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 08.11.24.
//

import Foundation

class FileLogger {
    /// Creates a log file with detailed information about the copy operation
    /// - Parameters:
    ///   - sourcePaths: Array of source file paths being copied
    ///   - targetPath: Destination path for the files
    ///   - attribute: Sorting attribute used
    ///   - userName: User performing the operation
    /// - Returns: URL of the created log file, or nil if creation failed
    static func createCopyLog(
        sourcePaths: [URL],
        targetPath: URL,
        userName: String
    ) -> URL? {
        let logFileName = "results.log"
        let logFileURL = targetPath.appendingPathComponent(logFileName)
        let timestamp = createCurrentTimeStamp()
        
        var logContent = """
        Copy Operation Log
        -----------------
        Date: \(timestamp)
        User: \(userName)
        
        Source Paths:
        """
        
        // Add source paths to log
        for (index, path) in sourcePaths.enumerated() {
            logContent += "\n\(index + 1). \(path.path)"
        }
        
        logContent += "\n\nDestination Path: \(targetPath.path)\n"
        logContent += "\n\nActions:"
        
        do {
            try logContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            // print("Log file created successfully at \(logFileURL.path)")
            return logFileURL
        } catch {
            // print("Error creating log file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Creates a log file with detailed information about the copy operation
    /// - Parameters:
    ///   - targetPath: Destination path for the files
    ///   - attribute: Sorting attribute used
    ///   - userName: User performing the operation
    /// - Returns: URL of the created log file, or nil if creation failed
    static func createDeviceLog(
        targetPath: URL,
        userName: String
    ) -> URL? {
        let logFileName = "device_information.log"
        let logFileURL = targetPath.appendingPathComponent(logFileName)
        let timestamp = createCurrentTimeStamp()
        
        var logContent = """
        Device information log
        -----------------
        Date: \(timestamp)
        -----------------\n
        
        """
        
        logContent += "=== System Information ===\n"
        logContent += TerminalClient.runCommand("uname -a") + "\n\n"
        
        logContent += "=== Current User ===\n"
        logContent += TerminalClient.runCommand("whoami") + "\n\n"
        
        logContent += "=== macOS Version ===\n"
        logContent += TerminalClient.runCommand("sw_vers") + "\n\n"
        
        logContent += "=== Serial Number ===\n"
        logContent += TerminalClient.runCommand("system_profiler SPHardwareDataType | grep 'Serial Number'") + "\n\n"
        
        logContent += "=== Hardware Overview ===\n"
        logContent += TerminalClient.runCommand("system_profiler SPHardwareDataType") + "\n\n"
        
        logContent += "=== Disk Drive Information ===\n"
        logContent += TerminalClient.runCommand("diskutil list") + "\n\n"
        
        logContent += "=== System Space Information ===\n"
        logContent += TerminalClient.runCommand("df -h") + "\n\n"
        
        logContent += "=== Memory Information ===\n"
        logContent += TerminalClient.runCommand("vm_stat") + "\n\n"
        
        logContent += "=== Network Interfaces ===\n"
        logContent += TerminalClient.runCommand("ifconfig") + "\n\n"
        
        logContent += "=== Installed Applications ===\n"
        logContent += TerminalClient.runCommand("ls /Applications") + "\n\n"
        
        logContent += "=== System Uptime ===\n"
        logContent += TerminalClient.runCommand("uptime") + "\n\n"
        
        logContent += "=== Last Boot Time ===\n"
        logContent += TerminalClient.runCommand("last reboot | head -n 1") + "\n"
        
        // Write to log file
        do {
            try logContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            // print("Log file created successfully at \(logFileURL.path)")
            return logFileURL
        } catch {
            // print("Error creating log file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Creates a log file with detailed information about the copy operation
    /// - Parameters:
    ///   - targetPath: Destination path for the files
    ///   - userName: User performing the operation
    /// - Returns: URL of the created log file, or nil if creation failed
    static func createErrorLog(
        targetPath: URL,
        userName: String
    ) -> URL? {
        let logFileName = "errors.log"
        let logFileURL = targetPath.appendingPathComponent(logFileName)
        let timestamp = createCurrentTimeStamp()
        let logContent = """
        Error log
        -----------------
        Date: \(timestamp)
        -----------------\n
        """
        
        // Write to log file
        do {
            try logContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            return logFileURL
        } catch {
            // print("Error creating log file: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    /// Appends additional information to an existing log file
    /// - Parameters:
    ///   - logFileURL: URL of the existing log file
    ///   - message: Additional message to append
    static func appendToLog(logFileURL: URL, message: String) {
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            
            let newlineData = "\n\(message)".data(using: .utf8)!
            fileHandle.write(newlineData)
            fileHandle.closeFile()
        } catch {
            // TODO
            // print("Error appending to log file: \(error.localizedDescription)")
        }
    }
    
    /// Creates a formatted timestamp for the current date and time.
    ///
    /// This function generates a timestamp string representing the current date and time
    /// in the format "dd-MM-yyyy HH:mm:ss". It uses the system's current date and time
    /// to create this timestamp.
    ///
    /// - Returns: A string representing the current timestamp formatted as "dd-MM-yyyy HH:mm:ss".
    public static func createCurrentTimeStamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        return timestamp
    }
}
