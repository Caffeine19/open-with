import Foundation
import SwiftUI

@MainActor
class InternetSchemesViewModel: ObservableObject {
    @Published var defaultBrowser: AppInfo?
    @Published var defaultMailClient: AppInfo?
    @Published var defaultFTP: AppInfo?
    @Published var defaultRSS: AppInfo?
    
    @Published var browserApps: [AppInfo] = []
    @Published var mailApps: [AppInfo] = []
    @Published var ftpApps: [AppInfo] = []
    @Published var rssApps: [AppInfo] = []
    
    @Published var isLoading = false
    @Published var showError = false
    var lastError: Error?
    
    private let lsManager = LaunchServicesManager.shared
    
    func loadData() async {
        isLoading = true
        
        // Yield to allow UI to show loading state
        await Task.yield()
        
        // Load browsers
        browserApps = lsManager.getHandlers(for: "http")
        defaultBrowser = lsManager.getDefaultHandler(for: "http")
        
        // Load mail clients
        mailApps = lsManager.getHandlers(for: "mailto")
        defaultMailClient = lsManager.getDefaultHandler(for: "mailto")
        
        // Load FTP clients
        ftpApps = lsManager.getHandlers(for: "ftp")
        defaultFTP = lsManager.getDefaultHandler(for: "ftp")
        
        // Load RSS readers
        rssApps = lsManager.getHandlers(for: "feed")
        defaultRSS = lsManager.getDefaultHandler(for: "feed")
        
        isLoading = false
    }
    
    func setDefaultBrowser(_ app: AppInfo) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: "http")
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: "https")
            defaultBrowser = app
        } catch {
            handleError(error)
        }
    }
    
    func setDefaultMailClient(_ app: AppInfo) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: "mailto")
            defaultMailClient = app
        } catch {
            handleError(error)
        }
    }
    
    func setDefaultFTP(_ app: AppInfo) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: "ftp")
            defaultFTP = app
        } catch {
            handleError(error)
        }
    }
    
    func setDefaultRSS(_ app: AppInfo) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: "feed")
            defaultRSS = app
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        lastError = error
        showError = true
    }
}
