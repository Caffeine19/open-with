import SwiftUI
import UniformTypeIdentifiers

// MARK: - App Association Info
struct AppAssociationInfo {
    var uriSchemes: [String] = []
    var viewerUTIs: [String] = []
    var editorUTIs: [String] = []
}

struct ApplicationsView: View {
    @StateObject private var viewModel = ApplicationsViewModel()
    @State private var searchText = ""
    @State private var selectedApp: AppInfo?

    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return viewModel.applications
        }
        return viewModel.applications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            // Left: App List
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    TextField("Search applications", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await viewModel.loadApplications() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredApps, selection: $selectedApp) { app in
                        HStack(spacing: 8) {
                            Image(nsImage: app.icon.resized(to: NSSize(width: 24, height: 24)))
                            Text(app.name)
                                .lineLimit(1)
                        }
                        .tag(app)
                    }
                }
            }
            .frame(minWidth: 220, idealWidth: 250)

            // Right: App Details
            if let app = selectedApp {
                AppDetailView(
                    app: app,
                    associations: viewModel.getAssociations(for: app),
                    onReassign: { items, targetApp in
                        viewModel.reassignItems(items, to: targetApp)
                    }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select an Application")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Applications")
        .task {
            await viewModel.loadApplications()
        }
    }
}

// MARK: - Selection Item Types
enum SelectableItem: Hashable {
    case uriScheme(String)
    case viewerUTI(String)
    case editorUTI(String)

    var displayName: String {
        switch self {
        case .uriScheme(let scheme): return "\(scheme)://"
        case .viewerUTI(let uti): return uti
        case .editorUTI(let uti): return uti
        }
    }
}

// MARK: - App Detail View
struct AppDetailView: View {
    let app: AppInfo
    let associations: AppAssociationInfo
    var onReassign: (Set<SelectableItem>, AppInfo) -> Void = { _, _ in }

    @State private var uriSchemesExpanded = true
    @State private var utisExpanded = true
    @State private var selectedItems: Set<SelectableItem> = []
    @State private var showingAppPicker = false
    @State private var availableApps: [AppInfo] = []

    private var hasSelection: Bool {
        !selectedItems.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Selection Toolbar
            if hasSelection {
                HStack {
                    Text("\(selectedItems.count) selected")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Clear") {
                        selectedItems.removeAll()
                    }
                    .buttonStyle(.borderless)

                    Button("Reassign") {
                        showingAppPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.bar)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // App Header
                    HStack(spacing: 16) {
                        Image(nsImage: app.icon.resized(to: NSSize(width: 64, height: 64)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.title)
                                .fontWeight(.semibold)

                            if let version = app.version {
                                Text("Version: \(version)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // URI Schemes Section
                    DisclosureGroup(isExpanded: $uriSchemesExpanded) {
                        if associations.uriSchemes.isEmpty {
                            Text("No URI schemes registered")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                // Select All / Deselect All for URI Schemes
                                HStack {
                                    Button("Select All") {
                                        for scheme in associations.uriSchemes {
                                            selectedItems.insert(.uriScheme(scheme))
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)

                                    Button("Deselect All") {
                                        for scheme in associations.uriSchemes {
                                            selectedItems.remove(.uriScheme(scheme))
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }
                                .padding(.bottom, 4)

                                ForEach(associations.uriSchemes, id: \.self) { scheme in
                                    SelectableRow(
                                        item: .uriScheme(scheme),
                                        icon: "link",
                                        text: "\(scheme)://",
                                        isSelected: selectedItems.contains(.uriScheme(scheme)),
                                        onToggle: { toggleSelection(.uriScheme(scheme)) }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        }
                    } label: {
                        Label("URI Schemes", systemImage: "link.circle")
                            .font(.headline)
                    }

                    // UTIs Section
                    DisclosureGroup(isExpanded: $utisExpanded) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Viewer UTIs
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Viewer")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if !associations.viewerUTIs.isEmpty {
                                        Button("Select All") {
                                            for uti in associations.viewerUTIs {
                                                selectedItems.insert(.viewerUTI(uti))
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)

                                        Button("Deselect") {
                                            for uti in associations.viewerUTIs {
                                                selectedItems.remove(.viewerUTI(uti))
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                    }
                                }

                                if associations.viewerUTIs.isEmpty {
                                    Text("None")
                                        .font(.body)
                                        .foregroundStyle(.tertiary)
                                } else {
                                    ForEach(associations.viewerUTIs, id: \.self) { uti in
                                        SelectableRow(
                                            item: .viewerUTI(uti),
                                            icon: "eye",
                                            text: uti,
                                            isSelected: selectedItems.contains(.viewerUTI(uti)),
                                            onToggle: { toggleSelection(.viewerUTI(uti)) }
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Editor UTIs
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Editor")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if !associations.editorUTIs.isEmpty {
                                        Button("Select All") {
                                            for uti in associations.editorUTIs {
                                                selectedItems.insert(.editorUTI(uti))
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)

                                        Button("Deselect") {
                                            for uti in associations.editorUTIs {
                                                selectedItems.remove(.editorUTI(uti))
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                    }
                                }

                                if associations.editorUTIs.isEmpty {
                                    Text("None")
                                        .font(.body)
                                        .foregroundStyle(.tertiary)
                                } else {
                                    ForEach(associations.editorUTIs, id: \.self) { uti in
                                        SelectableRow(
                                            item: .editorUTI(uti),
                                            icon: "pencil",
                                            text: uti,
                                            isSelected: selectedItems.contains(.editorUTI(uti)),
                                            onToggle: { toggleSelection(.editorUTI(uti)) }
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    } label: {
                        Label("Uniform Type Identifiers", systemImage: "doc.circle")
                            .font(.headline)
                    }

                    Spacer()

                    // App Path
                    Divider()

                    HStack {
                        if let path = app.path {
                            Text(path.path)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        if let path = app.path {
                            Button {
                                NSWorkspace.shared.selectFile(
                                    nil, inFileViewerRootedAtPath: path.path)
                            } label: {
                                Image(systemName: "magnifyingglass.circle")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderless)
                            .help("Show in Finder")
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 400)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                selectedItems: selectedItems,
                onSelect: { targetApp in
                    onReassign(selectedItems, targetApp)
                    selectedItems.removeAll()
                }
            )
        }
        .onAppear {
            loadAvailableApps()
        }
    }

    private func toggleSelection(_ item: SelectableItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }

    private func loadAvailableApps() {
        availableApps = LaunchServicesManager.shared.getAllApplications()
    }
}

// MARK: - Selectable Row
struct SelectableRow: View {
    let item: SelectableItem
    let icon: String
    let text: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 18)
                .onTapGesture { onToggle() }

            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(text)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}

// MARK: - App Picker Sheet
struct AppPickerSheet: View {
    let selectedItems: Set<SelectableItem>
    let onSelect: (AppInfo) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var isLoading = true

    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Reassign \(selectedItems.count) items to:")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Search
            TextField("Search applications", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)

            // App List
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApps) { app in
                    HStack(spacing: 12) {
                        Image(nsImage: app.icon.resized(to: NSSize(width: 24, height: 24)))

                        VStack(alignment: .leading) {
                            Text(app.name)
                                .font(.body)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(app)
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 500)
        .task {
            apps = LaunchServicesManager.shared.getAllApplications()
            isLoading = false
        }
    }
}

@MainActor
class ApplicationsViewModel: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var isLoading = false

    private let lsManager = LaunchServicesManager.shared

    func loadApplications() async {
        isLoading = true

        // Yield to allow UI to show loading state
        await Task.yield()

        applications = lsManager.getAllApplications()
        isLoading = false
    }

    func getAssociations(for app: AppInfo) -> AppAssociationInfo {
        // Get content directly from app's Info.plist
        guard let appPath = app.path?.path else {
            return AppAssociationInfo()
        }

        let content = lsManager.getHandledContent(for: appPath)

        return AppAssociationInfo(
            uriSchemes: content.uriSchemes,
            viewerUTIs: content.viewerUTIs,
            editorUTIs: content.editorUTIs
        )
    }

    func reassignItems(_ items: Set<SelectableItem>, to targetApp: AppInfo) {
        for item in items {
            do {
                switch item {
                case .uriScheme(let scheme):
                    try lsManager.setDefaultHandler(targetApp.bundleIdentifier, for: scheme)
                case .viewerUTI(let uti):
                    try lsManager.setDefaultHandler(
                        targetApp.bundleIdentifier, for: uti, role: .viewer)
                case .editorUTI(let uti):
                    try lsManager.setDefaultHandler(
                        targetApp.bundleIdentifier, for: uti, role: .editor)
                }
            } catch {
                print("Failed to reassign \(item): \(error)")
            }
        }
        // Trigger UI refresh
        objectWillChange.send()
    }
}

#Preview {
    NavigationStack {
        ApplicationsView()
    }
    .frame(width: 800, height: 600)
}
