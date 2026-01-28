import Foundation

enum LaunchServicesError: LocalizedError {
    case setHandlerFailed(status: OSStatus, scheme: String)
    case getHandlerFailed(scheme: String)
    case invalidBundleIdentifier(String)
    
    var errorDescription: String? {
        switch self {
        case .setHandlerFailed(let status, let scheme):
            return "Failed to set handler for \(scheme). Error code: \(status)"
        case .getHandlerFailed(let scheme):
            return "Failed to get handler for \(scheme)"
        case .invalidBundleIdentifier(let bundleID):
            return "Invalid bundle identifier: \(bundleID)"
        }
    }
}
