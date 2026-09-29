import Luminare
import SwiftUI
import UniformTypeIdentifiers

struct FileTypesView: View {
    @StateObject private var viewModel = FileTypesViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var filteredTypes: [FileTypeItem] {
        if searchText.isEmpty {
            return viewModel.fileTypes
        }
        return viewModel.fileTypes.filter {
            $0.uti.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
                || $0.extensions.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                placeholder: "Search file types",
                text: $searchText,
                focused: $isSearchFocused,
                onRefresh: {
                    Task { await viewModel.loadFileTypes() }
                }
            )

            if viewModel.isLoading {
                ProgressView("Loading file types...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.fileTypes.isEmpty {
                EmptyStateView(
                    icon: "doc.circle",
                    title: "No File Types Found",
                    message: "Unable to load registered file types"
                )
            } else {
                List(filteredTypes) { item in
                    FileTypeRow(item: item, viewModel: viewModel)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 2, leading: 12, bottom: 2, trailing: 12))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 8)
            }
        }
        .background {
            Button("") { isSearchFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .task {
            await viewModel.loadFileTypes()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
    }
}

struct FileTypeRow: View {
    let item: FileTypeItem
    @ObservedObject var viewModel: FileTypesViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: item.icon.resized(to: NSSize(width: 22, height: 22)))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if !item.extensions.isEmpty {
                        Text(item.extensions.map { ".\($0)" }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.uti)
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.tertiary)
                }
            }
            .layoutPriority(1)

            Spacer()

            RolePicker(
                role: "Viewer",
                selectedApp: item.viewerHandler,
                availableApps: item.availableHandlers,
                onSelect: { app in
                    viewModel.setHandler(app, for: item.uti, role: .viewer)
                }
            )

            RolePicker(
                role: "Editor",
                selectedApp: item.editorHandler,
                availableApps: item.availableHandlers,
                onSelect: { app in
                    viewModel.setHandler(app, for: item.uti, role: .editor)
                }
            )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .hoverRowHighlight()
    }
}

struct RolePicker: View {
    /// Fixed picker column width so viewer/editor columns align across rows.
    static let pickerWidth: CGFloat = 220

    let role: String
    let selectedApp: AppInfo?
    let availableApps: [AppInfo]
    let onSelect: (AppInfo) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(role + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            AppMenuPicker(
                apps: availableApps,
                allowsNone: true,
                width: Self.pickerWidth,
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

#Preview {
    FileTypesView()
        .frame(width: 800, height: 600)
}
