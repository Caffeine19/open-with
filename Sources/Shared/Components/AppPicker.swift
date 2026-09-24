import AppKit
import Luminare
import SwiftUI

/// A selectable application entry inside an ``AppMenuPicker``.
enum AppChoice: Hashable {
    case none
    case app(AppInfo)
}

/// A Luminare-styled popup for choosing an application handler.
struct AppMenuPicker: View {
    let apps: [AppInfo]
    var allowsNone: Bool = false
    let selection: AppInfo?
    var onCommit: (AppInfo?) -> Void = { _ in }

    var body: some View {
        if apps.isEmpty {
            Text("No apps available")
                .foregroundStyle(.tertiary)
        } else {
            LuminareCompactPicker(
                selection: Binding(
                    get: { selection.map(AppChoice.app) ?? .none },
                    set: { choice in
                        switch choice {
                        case .none: onCommit(nil)
                        case .app(let app): onCommit(app)
                        }
                    }
                )
            ) {
                if allowsNone {
                    Text("None")
                        .tag(AppChoice.none)
                }
                ForEach(apps) { app in
                    AppChoiceLabel(app: app)
                        .tag(AppChoice.app(app))
                }
            }
            .luminareCompactPickerStyle(.menu)
            .frame(minWidth: 130, alignment: .trailing)
        }
    }
}

/// Icon + name shown inside app menu pickers.
struct AppChoiceLabel: View {
    let app: AppInfo

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: app.icon.resized(to: NSSize(width: 14, height: 14)))
            Text(app.name)
        }
    }
}

/// A labeled row selecting the default app for a URL scheme (Internet pane).
struct AppPicker: View {
    let title: String
    @Binding var selectedApp: AppInfo?
    let availableApps: [AppInfo]
    let onSelect: (AppInfo) -> Void

    var body: some View {
        LuminareCompose(title) {
            AppMenuPicker(
                apps: availableApps,
                selection: selectedApp,
                onCommit: { app in
                    if let app {
                        onSelect(app)
                    }
                }
            )
        }
    }
}
