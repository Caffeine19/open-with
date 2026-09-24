import Foundation
import SwiftUI

struct URISchemeItem: Identifiable {
    let id: String
    let scheme: String
    var handler: AppInfo?
    var availableHandlers: [AppInfo]
    
    init(scheme: String, handler: AppInfo?, availableHandlers: [AppInfo]) {
        self.id = scheme
        self.scheme = scheme
        self.handler = handler
        self.availableHandlers = availableHandlers
    }
}

@MainActor
class URISchemesViewModel: ObservableObject {
    @Published var schemes: [URISchemeItem] = []
    // Starts `true` so the first frame shows loading, not the empty state.
    @Published var isLoading = true
    @Published var showError = false
    var lastError: Error?
    
    private let lsManager = LaunchServicesManager.shared
    
    func loadSchemes() async {
        isLoading = true
        schemes = []
        
        // Yield to allow UI to show loading state
        await Task.yield()
        
        var loadedSchemes: [URISchemeItem] = []
        
        // Get all registered schemes dynamically from the system
        let allSchemes = lsManager.getAllSchemes()
        
        for scheme in allSchemes {
            let handlers = lsManager.getHandlers(for: scheme)
            if !handlers.isEmpty {
                let defaultHandler = lsManager.getDefaultHandler(for: scheme)
                loadedSchemes.append(URISchemeItem(
                    scheme: scheme,
                    handler: defaultHandler,
                    availableHandlers: handlers
                ))
            }
        }
        
        // Sort by scheme name
        schemes = loadedSchemes.sorted { $0.scheme.lowercased() < $1.scheme.lowercased() }
        isLoading = false
    }
    
    func setHandler(_ app: AppInfo, for scheme: String) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: scheme)
            
            // Update the local state
            if let index = schemes.firstIndex(where: { $0.scheme == scheme }) {
                schemes[index].handler = app
            }
        } catch {
            lastError = error
            showError = true
        }
    }
}
