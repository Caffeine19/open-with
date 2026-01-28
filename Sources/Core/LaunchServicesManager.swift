import Foundation
import AppKit
import UniformTypeIdentifiers

// Private Launch Services APIs for discovering all registered schemes and UTIs
@_silgen_name("_LSCopySchemesAndHandlerURLs")
func LSCopySchemesAndHandlerURLs(_ schemes: UnsafeMutablePointer<NSArray?>, _ handlers: UnsafeMutablePointer<NSMutableArray?>) -> OSStatus

@_silgen_name("_UTCopyDeclaredTypeIdentifiers")
func UTCopyDeclaredTypeIdentifiers() -> NSArray

/// Manages interactions with macOS Launch Services for default app handling
@MainActor
class LaunchServicesManager: ObservableObject {
    static let shared = LaunchServicesManager()
    
    private init() {}
    
    // MARK: - URL Scheme Handlers
    
    /// Get the default handler for a URL scheme
    func getDefaultHandler(for scheme: String) -> AppInfo? {
        guard let bundleID = LSCopyDefaultHandlerForURLScheme(scheme as CFString)?
            .takeRetainedValue() as String? else {
            return nil
        }
        return AppInfo(bundleIdentifier: bundleID)
    }
    
    /// Get all handlers for a URL scheme
    func getHandlers(for scheme: String) -> [AppInfo] {
        guard let handlers = LSCopyAllHandlersForURLScheme(scheme as CFString)?
            .takeRetainedValue() as? [String] else {
            return []
        }
        return handlers.compactMap { AppInfo(bundleIdentifier: $0) }
    }
    
    /// Set the default handler for a URL scheme
    func setDefaultHandler(_ bundleID: String, for scheme: String) throws {
        let status = LSSetDefaultHandlerForURLScheme(
            scheme as CFString,
            bundleID as CFString
        )
        if status != noErr {
            throw LaunchServicesError.setHandlerFailed(status: status, scheme: scheme)
        }
    }
    
    /// Get all registered URI schemes with their default handlers
    func getAllSchemesAndHandlers() -> [(scheme: String, handler: String?)] {
        var schemesArray: NSArray?
        var handlersArray: NSMutableArray?
        
        guard LSCopySchemesAndHandlerURLs(&schemesArray, &handlersArray) == 0,
              let schemes = schemesArray as? [String],
              let handlers = handlersArray as? [URL] else {
            return []
        }
        
        var result: [(String, String?)] = []
        for (index, scheme) in schemes.enumerated() {
            // Skip wildcard scheme
            guard scheme != "*" else { continue }
            
            let handlerPath: String?
            if index < handlers.count {
                handlerPath = handlers[index].path
            } else {
                handlerPath = nil
            }
            result.append((scheme, handlerPath))
        }
        
        return result.sorted { $0.0.lowercased() < $1.0.lowercased() }
    }
    
    /// Get all registered URI schemes
    func getAllSchemes() -> [String] {
        return getAllSchemesAndHandlers().map { $0.scheme }
    }
    
    // MARK: - UTI Handlers
    
    /// Get the default handler for a UTI
    func getDefaultHandler(for uti: String, role: LSRolesMask = [.viewer, .editor]) -> AppInfo? {
        guard let bundleID = LSCopyDefaultRoleHandlerForContentType(
            uti as CFString,
            role
        )?.takeRetainedValue() as String? else {
            return nil
        }
        return AppInfo(bundleIdentifier: bundleID)
    }
    
    /// Get all handlers for a UTI
    func getHandlers(for uti: String, role: LSRolesMask = [.viewer, .editor]) -> [AppInfo] {
        guard let handlers = LSCopyAllRoleHandlersForContentType(
            uti as CFString,
            role
        )?.takeRetainedValue() as? [String] else {
            return []
        }
        return handlers.compactMap { AppInfo(bundleIdentifier: $0) }
    }
    
    /// Set the default handler for a UTI
    func setDefaultHandler(_ bundleID: String, for uti: String, role: LSRolesMask = .all) throws {
        let status = LSSetDefaultRoleHandlerForContentType(
            uti as CFString,
            role,
            bundleID as CFString
        )
        if status != noErr {
            throw LaunchServicesError.setHandlerFailed(status: status, scheme: uti)
        }
    }
    
    /// Get all declared UTIs in the system
    func getAllDeclaredUTIs() -> [String] {
        let allUTIs = UTCopyDeclaredTypeIdentifiers() as! [String]
        
        // Filter to only include UTIs that conform to public.item or public.content
        // These are the "meaningful" file types, excluding device types, etc.
        return allUTIs.filter { uti in
            UTTypeConformsTo(uti as CFString, "public.item" as CFString) ||
            UTTypeConformsTo(uti as CFString, "public.content" as CFString)
        }.sorted { $0.lowercased() < $1.lowercased() }
    }
    
    /// Get all UTIs with their default handlers
    func getAllUTIsAndHandlers() -> [(uti: String, handler: AppInfo?)] {
        let utis = getAllDeclaredUTIs()
        return utis.map { uti in
            (uti, getDefaultHandler(for: uti))
        }
    }
    
    // MARK: - Application Discovery
    
    /// Get all applications from Applications directories
    func getAllApplications() -> [AppInfo] {
        var allApps: Set<AppInfo> = []
        
        let appDirectories = FileManager.default.urls(
            for: .applicationDirectory,
            in: .allDomainsMask
        )
        
        for directory in appDirectories {
            if let contents = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) {
                for url in contents where url.pathExtension == "app" {
                    if let bundle = Bundle(url: url),
                       let bundleID = bundle.bundleIdentifier,
                       let app = AppInfo(bundleIdentifier: bundleID) {
                        allApps.insert(app)
                    }
                }
            }
        }
        
        return Array(allApps).sorted { $0.name < $1.name }
    }
    
    // MARK: - Application Content Discovery
    
    /// Get all URI schemes and UTIs that an application handles
    func getHandledContent(for appPath: String) -> (uriSchemes: [String], viewerUTIs: [String], editorUTIs: [String]) {
        guard let bundle = Bundle(path: appPath),
              let infoDict = bundle.infoDictionary,
              (infoDict["CFBundlePackageType"] as? String) == "APPL" else {
            return ([], [], [])
        }
        
        var uriSchemes: Set<String> = []
        var viewerUTIs: Set<String> = []
        var editorUTIs: Set<String> = []
        
        // Get URI Schemes from CFBundleURLTypes
        if let urlTypes = infoDict["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in urlTypes {
                if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                    uriSchemes.formUnion(schemes)
                }
            }
        }
        
        // Get UTIs from CFBundleDocumentTypes
        if let docTypes = infoDict["CFBundleDocumentTypes"] as? [[String: Any]] {
            for docType in docTypes {
                let role = (docType["CFBundleTypeRole"] as? String)?.lowercased() ?? "viewer"
                
                // Get UTIs directly declared
                if let utis = docType["LSItemContentTypes"] as? [String] {
                    for uti in utis {
                        if role == "editor" {
                            editorUTIs.insert(uti)
                        } else {
                            viewerUTIs.insert(uti)
                        }
                    }
                }
                
                // Get UTIs from file extensions
                if let extensions = docType["CFBundleTypeExtensions"] as? [String] {
                    for ext in extensions {
                        if let uti = UTTypeCreatePreferredIdentifierForTag(
                            kUTTagClassFilenameExtension,
                            ext as CFString,
                            "public.content" as CFString
                        )?.takeRetainedValue() as String? {
                            // Skip dynamic UTIs (dyn.xxx)
                            if !UTTypeIsDynamic(uti as CFString) {
                                if role == "editor" {
                                    editorUTIs.insert(uti)
                                } else {
                                    viewerUTIs.insert(uti)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return (
            Array(uriSchemes).sorted(),
            Array(viewerUTIs).sorted(),
            Array(editorUTIs).sorted()
        )
    }
}
