import Luminare
import SwiftUI

struct ContentView: View {
    @ObservedObject private var router = AppRouter.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.luminareTitleBarHeight) private var titleBarHeight

    var body: some View {
        LuminareDividedStack {
            LuminareSidebar {
                LuminareSidebarSection(selection: $router.selection, items: Category.allCases)
            }
            .frame(width: 180)
            .padding(.top, titleBarHeight)
            .luminareBackground()
            .border(.clear, width: 0)

            LuminarePane {
                router.selection.view()
            } header: {
                HStack {
                    router.selection.decoratedImageView
                    Text(router.selection.title)
                        .font(.title2)
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .luminarePaneLayout(.none)
        }
        .frame(minWidth: 920, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .ignoresSafeArea()
        .luminareBackground()
        .background {
            WindowBackgroundTint(opacity: colorScheme == .dark ? 0.3 : 0)
                .id(router.selection)
                .allowsHitTesting(false)
        }
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
