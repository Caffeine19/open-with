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
            HStack(spacing: 8) {
                TextField("Search file types", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)
                Button {
                    Task { await viewModel.loadFileTypes() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if viewModel.isLoading {
                ProgressView("Loading file types...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.fileTypes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No File Types Found")
                        .font(.title2)
                    Text("Unable to load registered file types")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredTypes) { item in
                    FileTypeRow(item: item, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("File Types")
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // File type icon
                Image(nsImage: item.icon.resized(to: NSSize(width: 20, height: 20)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.description)
                        .font(.headline)

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

                Spacer()
            }

            // Role pickers
            HStack(spacing: 20) {
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
            .padding(.leading, 44)
        }
        .padding(.vertical, 6)
    }
}

struct RolePicker: View {
    let role: String
    let selectedApp: AppInfo?
    let availableApps: [AppInfo]
    let onSelect: (AppInfo) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(role + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)

            if availableApps.isEmpty {
                Text("No apps")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Picker(
                    "",
                    selection: Binding(
                        get: { selectedApp },
                        set: { newApp in
                            if let app = newApp {
                                onSelect(app)
                            }
                        }
                    )
                ) {
                    Text("None")
                        .tag(nil as AppInfo?)

                    Divider()

                    ForEach(availableApps) { app in
                        HStack {
                            Image(nsImage: app.icon.resized(to: NSSize(width: 12, height: 12)))
                            Text(app.name)
                        }
                        .tag(app as AppInfo?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FileTypesView()
    }
    .frame(width: 800, height: 600)
}
