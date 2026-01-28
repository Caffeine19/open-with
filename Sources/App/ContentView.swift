import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: Category = .internet
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(Category.allCases, selection: $selectedCategory) { category in
                Label(category.title, systemImage: category.icon)
                    .tag(category)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
            .navigationTitle("Categories")
        } detail: {
            // Detail View
            Group {
                switch selectedCategory {
                case .internet:
                    InternetSchemesView()
                case .uriSchemes:
                    URISchemesView()
                case .fileTypes:
                    FileTypesView()
                case .applications:
                    ApplicationsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

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
        case .fileTypes: return "doc.fill"
        case .applications: return "app.badge"
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
