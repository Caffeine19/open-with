import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileTypeItem: Identifiable {
    let id: String
    let uti: String
    let description: String
    let extensions: [String]
    let icon: NSImage
    var viewerHandler: AppInfo?
    var editorHandler: AppInfo?
    var availableHandlers: [AppInfo]
    
    init(uti: String, description: String, extensions: [String], icon: NSImage,
         viewerHandler: AppInfo?, editorHandler: AppInfo?, availableHandlers: [AppInfo]) {
        self.id = uti
        self.uti = uti
        self.description = description
        self.extensions = extensions
        self.icon = icon
        self.viewerHandler = viewerHandler
        self.editorHandler = editorHandler
        self.availableHandlers = availableHandlers
    }
}

@MainActor
class FileTypesViewModel: ObservableObject {
    @Published var fileTypes: [FileTypeItem] = []
    @Published var isLoading = false
    @Published var showError = false
    var lastError: Error?
    
    private let lsManager = LaunchServicesManager.shared
    
    func loadFileTypes() async {
        isLoading = true
        fileTypes = []
        
        // Yield to allow UI to show loading state
        await Task.yield()
        
        var loadedTypes: [FileTypeItem] = []
        
        // Get all declared UTIs dynamically from the system
        let allUTIs = lsManager.getAllDeclaredUTIs()
        
        for uti in allUTIs {
            // Get handlers for both viewer and editor roles
            let viewerHandlers = lsManager.getHandlers(for: uti, role: .viewer)
            let editorHandlers = lsManager.getHandlers(for: uti, role: .editor)
            
            // Combine all available handlers
            var allHandlers = Set(viewerHandlers)
            allHandlers.formUnion(editorHandlers)
            
            // Only include UTIs that have at least one handler
            if !allHandlers.isEmpty {
                let viewerHandler = lsManager.getDefaultHandler(for: uti, role: .viewer)
                let editorHandler = lsManager.getDefaultHandler(for: uti, role: .editor)
                
                // Get description
                let description = getDescription(for: uti) ?? uti
                
                // Get icon
                let icon = getIcon(for: uti)
                
                // Get extensions
                let extensions = getExtensions(for: uti)
                
                loadedTypes.append(FileTypeItem(
                    uti: uti,
                    description: description,
                    extensions: extensions,
                    icon: icon,
                    viewerHandler: viewerHandler,
                    editorHandler: editorHandler,
                    availableHandlers: Array(allHandlers).sorted { $0.name < $1.name }
                ))
            }
        }
        
        // Sort by description
        fileTypes = loadedTypes.sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
        isLoading = false
    }
    
    private func getDescription(for uti: String) -> String? {
        if let utType = UTType(uti) {
            return utType.localizedDescription
        }
        return nil
    }
    
    private func getIcon(for uti: String) -> NSImage {
        if let utType = UTType(uti) {
            return NSWorkspace.shared.icon(for: utType)
        }
        return NSWorkspace.shared.icon(for: .data)
    }
    
    private func getExtensions(for uti: String) -> [String] {
        if let utType = UTType(uti) {
            return utType.tags[.filenameExtension] ?? []
        }
        return []
    }
    
    func setHandler(_ app: AppInfo, for uti: String, role: LSRolesMask) {
        do {
            try lsManager.setDefaultHandler(app.bundleIdentifier, for: uti, role: role)
            
            // Update local state
            if let index = fileTypes.firstIndex(where: { $0.uti == uti }) {
                if role == .viewer {
                    fileTypes[index].viewerHandler = app
                } else if role == .editor {
                    fileTypes[index].editorHandler = app
                }
            }
        } catch {
            lastError = error
            showError = true
        }
    }
}
