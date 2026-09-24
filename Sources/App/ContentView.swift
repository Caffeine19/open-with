import Luminare
import SwiftUI

struct ContentView: View {
    @State private var selection: Category = .internet
    @Environment(\.luminareTitleBarHeight) private var titleBarHeight

    var body: some View {
        LuminareDividedStack {
            LuminareSidebar {
                LuminareSidebarSection(selection: $selection, items: Category.allCases)
            }
            .frame(width: 180)
            .padding(.top, titleBarHeight)
            .luminareBackground()
            .border(.clear, width: 0)

            LuminarePane {
                selection.view()
            } header: {
                HStack {
                    selection.decoratedImageView
                    Text(selection.title)
                        .font(.title2)
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .luminarePaneLayout(.none)
        }
        .frame(minWidth: 880, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .ignoresSafeArea()
        .luminareBackground()
        .background {
            keyboardShortcutButtons
        }
    }

    /// Hidden buttons binding ⌘1–⌘4 to the sidebar tabs.
    private var keyboardShortcutButtons: some View {
        Group {
            Button("") { selection = .internet }
                .keyboardShortcut("1", modifiers: .command)
            Button("") { selection = .uriSchemes }
                .keyboardShortcut("2", modifiers: .command)
            Button("") { selection = .fileTypes }
                .keyboardShortcut("3", modifiers: .command)
            Button("") { selection = .applications }
                .keyboardShortcut("4", modifiers: .command)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }
}

// MARK: - Categories

enum Category: String, CaseIterable, Identifiable {
    case internet
    case uriSchemes
    case fileTypes
    case applications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .internet: return "Internet"
        case .uriSchemes: return "URI Schemes"
        case .fileTypes: return "File Types"
        case .applications: return "Applications"
        }
    }

    var icon: String {
        switch self {
        case .internet: return "globe"
        case .uriSchemes: return "link"
        case .fileTypes: return "doc"
        case .applications: return "app.badge"
        }
    }

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .internet: InternetSchemesView()
        case .uriSchemes: URISchemesView()
        case .fileTypes: FileTypesView()
        case .applications: ApplicationsView()
        }
    }
}

extension Category: LuminareTabItem {
    var image: Image { Image(systemName: icon) }
}

#Preview {
    ContentView()
        .frame(width: 1040, height: 720)
}
