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
    /// Approximate horizontal chrome around the label: icon column (14),
    /// spacing, trailing chevron and popup padding.
    static let chromeWidth: CGFloat = 56

    let apps: [AppInfo]
    var allowsNone: Bool = false
    /// Fixed column width. When set, the popup button and every menu row
    /// share the same width so that pickers align across rows.
    var width: CGFloat? = nil
    let selection: AppInfo?
    var onCommit: (AppInfo?) -> Void = { _ in }

    private var textWidth: CGFloat? {
        width.map { $0 - Self.chromeWidth }
    }

    var body: some View {
        if apps.isEmpty {
            Text("No apps available")
                .foregroundStyle(.tertiary)
                .frame(width: width, alignment: .leading)
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
                    AppChoiceLabel(title: "None", textWidth: textWidth)
                        .tag(AppChoice.none)
                }
                ForEach(apps) { app in
                    AppChoiceLabel(app: app, textWidth: textWidth)
                        .tag(AppChoice.app(app))
                }
            }
            .luminareCompactPickerStyle(.menu)
            .frame(
                minWidth: width ?? 130,
                maxWidth: width,
                alignment: width == nil ? .trailing : .leading
            )
        }
    }
}

/// Icon + name shown inside app menu pickers.
struct AppChoiceLabel: View {
    var icon: NSImage? = nil
    let title: String
    /// When set, the name column has a fixed width (truncated if needed) so
    /// that every popup button in a column ends up the same width.
    var textWidth: CGFloat? = nil

    init(app: AppInfo, textWidth: CGFloat? = nil) {
        self.icon = app.icon
        self.title = app.name
        self.textWidth = textWidth
    }

    init(title: String, textWidth: CGFloat? = nil) {
        self.title = title
        self.textWidth = textWidth
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(nsImage: icon.resized(to: NSSize(width: 14, height: 14)))
            } else if textWidth != nil {
                // Reserve the icon column so "None" aligns with app rows.
                Color.clear
                    .frame(width: 14, height: 14)
            }

            Text(title)
                .lineLimit(textWidth == nil ? nil : 1)
                .truncationMode(.middle)
                .frame(width: textWidth, alignment: .leading)
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
