import Foundation
import UIKit
import os.log
import SwiftSignalKit

public final class LightGramDiagnostics {
    public static let shared = LightGramDiagnostics()
    
    private let queue = DispatchQueue(label: "site.lightgram.diagnostics", qos: .utility)
    private let lock = NSLock()
    
    private let appSupportURL: URL
    private let documentsURL: URL
    
    public let breadcrumbsURL: URL
    public let breadcrumbsPrevURL: URL
    public let lastStageURL: URL
    public let crashMarkerURL: URL
    
    // Mirror in Documents directory for native iOS Files app access
    public let docBreadcrumbsURL: URL
    public let docLastStageURL: URL
    public let docCrashReportURL: URL
    
    private var fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    
    private let maxLogSizeBytes: Int64 = 512 * 1024 // 512 KB
    
    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let diagDir = appSupport.appendingPathComponent("LightGramDiagnostics", isDirectory: true)
        if !fm.fileExists(atPath: diagDir.path) {
            try? fm.createDirectory(at: diagDir, withIntermediateDirectories: true)
        }
        self.appSupportURL = diagDir
        
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? appSupport
        self.documentsURL = docs
        
        self.breadcrumbsURL = diagDir.appendingPathComponent("breadcrumbs.log")
        self.breadcrumbsPrevURL = diagDir.appendingPathComponent("breadcrumbs.prev.log")
        self.lastStageURL = diagDir.appendingPathComponent("last_stage.txt")
        self.crashMarkerURL = diagDir.appendingPathComponent("settings_opening_marker.txt")
        
        self.docBreadcrumbsURL = docs.appendingPathComponent("lightgram_breadcrumbs.log")
        self.docLastStageURL = docs.appendingPathComponent("lightgram_last_stage.txt")
        self.docCrashReportURL = docs.appendingPathComponent("lightgram_last_crash.txt")
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm:ss.SSS"
        self.dateFormatter = df
        
        self.openLogFile()
        
        // Log startup banner
        self.logInternal("=== LIGHTGRAM DIAGNOSTICS INITIALIZED ===")
        self.logInternal("Device: \(UIDevice.current.model) iOS: \(UIDevice.current.systemVersion)")
        if self.didCrashDuringSettingsOpen() {
            let lastStage = (try? String(contentsOf: self.lastStageURL, encoding: .utf8)) ?? "Unknown"
            self.logInternal("CRASH DETECTED ON PREVIOUS RUN! Last stage: \(lastStage)")
        }
    }
    
    private func openLogFile() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: self.breadcrumbsURL.path) {
            fm.createFile(atPath: self.breadcrumbsURL.path, contents: nil)
        }
        self.fileHandle = try? FileHandle(forWritingTo: self.breadcrumbsURL)
        self.fileHandle?.seekToEndOfFile()
    }
    
    // MARK: - Breadcrumb Logging
    
    public func log(_ event: String, details: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        let fileName = (file as NSString).lastPathComponent
        let threadInfo = self.currentExecutionEnvironment()
        let timestamp = self.dateFormatter.string(from: Date())
        
        let detailString = details != nil ? " -> \(details!)" : ""
        let entry = "[\(timestamp)] [\(threadInfo)] \(event)\(detailString) (\(fileName):\(line))\n"
        
        self.appendAndSync(entry)
        
        // Mirror to Apple system Unified Logging
        let osLog = OSLog(subsystem: "site.lightgram.ios", category: "Breadcrumbs")
        os_log("%{public}@", log: osLog, type: .default, entry)
    }
    
    private func logInternal(_ message: String) {
        let timestamp = self.dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)\n"
        self.appendAndSync(entry)
    }
    
    private func appendAndSync(_ line: String) {
        self.queue.async {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            guard let data = line.data(using: .utf8) else { return }
            
            // Check size limit and rotate if needed
            if let handle = self.fileHandle {
                let currentOffset = handle.offsetInFile
                if currentOffset > UInt64(self.maxLogSizeBytes) {
                    handle.closeFile()
                    self.rotateLogs()
                    self.openLogFile()
                }
            }
            
            if let handle = self.fileHandle {
                handle.write(data)
                handle.synchronizeFile()
            }
            
            // Mirror to Documents for Files app visibility
            if let docHandle = try? FileHandle(forWritingTo: self.docBreadcrumbsURL) {
                docHandle.seekToEndOfFile()
                docHandle.write(data)
                docHandle.synchronizeFile()
                docHandle.closeFile()
            } else {
                try? line.write(to: self.docBreadcrumbsURL, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func rotateLogs() {
        let fm = FileManager.default
        let _ = try? fm.removeItem(at: self.breadcrumbsPrevURL)
        let _ = try? fm.moveItem(at: self.breadcrumbsURL, to: self.breadcrumbsPrevURL)
    }
    
    private func currentExecutionEnvironment() -> String {
        let isMain = Thread.isMainThread ? "M" : "B"
        let threadName = Thread.current.name?.isEmpty == false ? Thread.current.name! : (Thread.isMainThread ? "main" : "bg")
        let queueLabel = String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) ?? "unk"
        return "\(isMain)|\(threadName)|\(queueLabel)"
    }
    
    // MARK: - Stage Tracking & Crash Detection
    
    public func recordStage(_ stage: String) {
        let timestamp = self.dateFormatter.string(from: Date())
        let content = "STAGE: \(stage) | TIME: \(timestamp) | ENV: \(self.currentExecutionEnvironment())"
        
        self.log("STAGE_REACHED: \(stage)")
        
        self.queue.async {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            try? content.write(to: self.lastStageURL, atomically: true, encoding: .utf8)
            try? content.write(to: self.docLastStageURL, atomically: true, encoding: .utf8)
        }
    }
    
    public func beginOpeningSettings() {
        let timestamp = self.dateFormatter.string(from: Date())
        let content = "IN_PROGRESS: OPENING_LIGHTGRAM_SETTINGS | START: \(timestamp)"
        
        self.log(">>> BEGIN_OPENING_SETTINGS")
        
        self.queue.async {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            try? content.write(to: self.crashMarkerURL, atomically: true, encoding: .utf8)
            try? content.write(to: self.lastStageURL, atomically: true, encoding: .utf8)
            try? content.write(to: self.docLastStageURL, atomically: true, encoding: .utf8)
        }
    }
    
    public func finishOpeningSettings() {
        let timestamp = self.dateFormatter.string(from: Date())
        let content = "SUCCESS: SETTINGS_PRESENTED_FULLY | TIME: \(timestamp)"
        
        self.log("<<< FINISH_OPENING_SETTINGS_SUCCESS")
        
        self.queue.async {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            // Remove crash marker indicating success
            let fm = FileManager.default
            let _ = try? fm.removeItem(at: self.crashMarkerURL)
            try? content.write(to: self.lastStageURL, atomically: true, encoding: .utf8)
            try? content.write(to: self.docLastStageURL, atomically: true, encoding: .utf8)
        }
    }
    
    public func didCrashDuringSettingsOpen() -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: self.crashMarkerURL.path)
    }
    
    public func clearCrashMarker() {
        let fm = FileManager.default
        let _ = try? fm.removeItem(at: self.crashMarkerURL)
    }
    
    public func lastRecordedStage() -> String {
        if let content = try? String(contentsOf: self.lastStageURL, encoding: .utf8) {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "None"
    }
    
    // MARK: - Export
    
    public func getAllLogFiles() -> [URL] {
        var files: [URL] = []
        let fm = FileManager.default
        
        let candidates = [
            self.breadcrumbsURL,
            self.breadcrumbsPrevURL,
            self.lastStageURL,
            self.crashMarkerURL,
            self.docBreadcrumbsURL,
            self.docLastStageURL,
            self.docCrashReportURL
        ]
        
        for url in candidates {
            if fm.fileExists(atPath: url.path) {
                if !files.contains(url) {
                    files.append(url)
                }
            }
        }
        return files
    }
    
    public func fullDiagnosticSummary() -> String {
        var summary = "=== LIGHTGRAM DIAGNOSTIC SUMMARY ===\n"
        summary += "Device: \(UIDevice.current.model) (\(UIDevice.current.systemName) \(UIDevice.current.systemVersion))\n"
        summary += "Crash Marker Exists: \(self.didCrashDuringSettingsOpen())\n"
        summary += "Last Stage: \(self.lastRecordedStage())\n\n"
        
        if let breadcrumbs = try? String(contentsOf: self.breadcrumbsURL, encoding: .utf8) {
            let lines = breadcrumbs.components(separatedBy: "\n")
            let recentLines = lines.suffix(60).joined(separator: "\n")
            summary += "--- RECENT BREADCRUMBS (Last 60 lines) ---\n\(recentLines)\n"
        }
        
        if let crashReport = try? String(contentsOf: self.docCrashReportURL, encoding: .utf8) {
            summary += "\n--- LAST EXCEPTION REPORT ---\n\(crashReport)\n"
        }
        
        return summary
    }
}
