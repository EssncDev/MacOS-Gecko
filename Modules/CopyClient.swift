//
//  CopyClient.swift
//  SwiftUI_Test
//
//  Created by DF-Augsburg on 11.11.24.
//

import Foundation
import SwiftUI
import CryptoKit

public class CopyClient {
    public var statusMessage: String = ""

    /// Copies files and directories from the source path to the target path, logging the status and errors.
    ///
    /// This function recursively copies files and directories from a source directory to a target directory.
    /// During the copy process, it logs the status of copied files and directories to a specified status log file.
    /// If any errors occur while copying files, those errors are logged to a specified error log file. If the target directory
    /// does not exist, it will be created automatically.
    ///
    /// - Parameters:
    ///   - sourcePath: The source directory from which files and subdirectories will be copied.
    ///   - targetPath: The target directory where the files and subdirectories will be copied to.
    ///   - statusLog: The URL of the log file where the status of the copied files and directories will be recorded.
    ///   - errorLog: The URL of the log file where errors encountered during the copy process will be logged.
    ///
    /// - Note: This function performs a recursive copy, meaning that subdirectories will also be copied along with their contents.
    func copyFiles(sourcePath: URL, targetPath: URL, statusLog: URL, errorLog: URL) async {
        do {
            let fileManager = FileManager.default
            
            // Check if the source path exists
            if fileManager.fileExists(atPath: sourcePath.path) {
                // Create the target directory if it doesn't exist
                if !fileManager.fileExists(atPath: targetPath.path) {
                    try fileManager.createDirectory(at: targetPath, withIntermediateDirectories: true, attributes: nil)
                    FileLogger.appendToLog(
                        logFileURL: statusLog,
                        message: "Copied Folder: \(targetPath.lastPathComponent) in \(targetPath.path)"
                    )
                }
                
                // Get the contents of the source directory
                let items = try fileManager.contentsOfDirectory(at: sourcePath, includingPropertiesForKeys: nil, options: [])
                
                for item in items {
                    let targetItemPath = targetPath.appendingPathComponent(item.lastPathComponent)
                    
                    do {
                        // Check if the item is a directory or a file
                        if item.hasDirectoryPath {
                            // Recursively copy the directory
                            await copyFiles(sourcePath: item, targetPath: targetItemPath, statusLog: statusLog, errorLog: errorLog)
                        } else {
                            // Copy the file
                            try fileManager.copyItem(at: item, to: targetItemPath)
                            
                            // Log the status
                            FileLogger.appendToLog(
                                logFileURL: statusLog,
                                message: "Copied File: \(item.path) to \(targetItemPath.path)"
                            )
                        }
                    } catch {
                        // Log the error for this specific item
                        FileLogger.appendToLog(
                            logFileURL: errorLog,
                            message: "Error copying \(item.path): \(error)"
                        )
                    }
                }
            } else {
                FileLogger.appendToLog(
                    logFileURL: errorLog,
                    message: "Source directory \(sourcePath.path) does not exist."
                )
            }
        } catch {
            FileLogger.appendToLog(
                logFileURL: errorLog,
                message: "Error during initial directory check: \(error)"
            )
        }
    }
    
    // unused
    public func calcSizes(directoryURL: URL) -> (folderCount: Int, fileCount: Int, totalSize: Int64) {
        var folderCount = 0
        var fileCount = 0
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        // Get the contents of the directory
        if let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    // Check if it's a directory or a file
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                    if resourceValues.isDirectory == true {
                        folderCount += 1
                    } else if resourceValues.isDirectory == false {
                        fileCount += 1
                        if let fileSize = resourceValues.fileSize {
                            totalSize += Int64(fileSize)
                        }
                    }
                } catch {
                    print("Error retrieving file information: \(error)")
                }
            }
        }
        return (folderCount, fileCount, totalSize)
    }
    
    // unused
    public func formatFileSize(_ size: Int64) -> String {
        let units: [String] = ["Bytes", "KB", "MB", "GB", "TB"]
        var sizeInBytes = Double(size)
        var unitIndex = 0
        while sizeInBytes >= 1024 && unitIndex < units.count - 1 {
            sizeInBytes /= 1024
            unitIndex += 1
        }
        return String(format: "%.2f %@", sizeInBytes, units[unitIndex])
    }
    
    /// Creates a DMG file from the specified folder and saves it to the target location.
    ///
    /// This function takes a folder at the specified `targetUrl`, uses the `hdiutil` command-line tool to create a DMG (Disk Image)
    /// file from that folder, and saves it to the same parent directory with a `.dmg` extension. The DMG file will be named the same as
    /// the folder, with the appropriate `.dmg` extension appended.
    ///
    /// - Parameters:
    ///   - targetUrl: The URL of the folder to be converted into a DMG file.
    ///
    /// - Note: The function uses the `hdiutil` command with the `-format UDZO` option for a compressed DMG file.
    ///         If any error occurs while running the command, it is captured and can be logged or handled accordingly.
    public func createDMG(targetUrl: URL) async {
        // last Folder Name is the DMG Name
        let dmgName = targetUrl.lastPathComponent
        let finalTargetPath = targetUrl.deletingLastPathComponent()
        
        // Define the command with the specific parameters
        let command = """
        hdiutil create -srcfolder "\(targetUrl.path)" -volname "dmgName" -format UDZO -o \(finalTargetPath)/\(dmgName).dmg
        """
        
        // run the terminal prompt
        do {
            try await TerminalClient.runCommandAsync(command)
        } catch {
            // Write in ErrorLog
        }
    }
    
    /// Computes the MD5 hash of the given data and returns the result as a hexadecimal string.
    ///
    /// This function takes a `Data` object, computes its MD5 hash using the `Insecure.MD5` cryptographic hash function,
    /// and returns the resulting hash as a string of hexadecimal characters. MD5 is a widely used hash function but should
    /// not be used for cryptographic security purposes due to vulnerabilities.
    ///
    /// - Parameters:
    ///   - data: The `Data` object to be hashed.
    ///
    /// - Returns: A hexadecimal string representing the MD5 hash of the input data.
    ///
    /// - Note: This function uses `Insecure.MD5` from the `CryptoKit` framework, which is suitable for non-security-critical
    ///         applications.
    private func md5(data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Computes the MD5 hash of a DMG file located at the specified URL.
    ///
    /// This function reads the contents of the DMG file at the given `dmgUrl`, computes its MD5 hash using the `md5(data:)`
    /// function, and returns the resulting hash as a hexadecimal string. If an error occurs while reading the file, it logs
    /// the error and returns `nil`.
    ///
    /// - Parameters:
    ///   - dmgUrl: The URL of the DMG file for which the MD5 hash is to be calculated.
    ///
    /// - Returns: The MD5 hash of the DMG file as a hexadecimal string, or `nil` if an error occurs while reading the file.
    ///
    /// - Note: This function uses the `md5(data:)` function to compute the hash
    public func md5OfDMG(dmgUrl: URL) async -> String? {
        do {
            let fileData = try await Task { () -> Data in
                return try Data(contentsOf: dmgUrl)
            }.value
            return md5(data: fileData)
        } catch {
            return nil
        }
    }
}
