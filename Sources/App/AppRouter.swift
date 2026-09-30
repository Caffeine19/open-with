import Foundation
import SwiftUI

/// Shared app-wide navigation state: which sidebar tab is selected.
///
/// Single source of truth bridging AppKit (View menu, ⌘1–⌘4) and SwiftUI
/// (sidebar + pane content), so menu checkmarks always match the sidebar.
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var selection: Category = .internet

    private init() {}
}
