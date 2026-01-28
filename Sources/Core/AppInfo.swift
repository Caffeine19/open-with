import Foundation
import AppKit

/// Represents information about an installed application
struct AppInfo: Identifiable, Hashable, Equatable {
    let id: String
    let bundleIdentifier: String
    let name: String
    let icon: NSImage
    let version: String?
    let path: URL?
    
    init?(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
              let bundle = Bundle(url: url) else {
            return nil
        }
        
        self.id = bundleIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                    bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                    url.deletingPathExtension().lastPathComponent
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        self.version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        self.path = url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}
