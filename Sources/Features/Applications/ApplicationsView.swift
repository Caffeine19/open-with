import Luminare
import SwiftUI
import UniformTypeIdentifiers

// MARK: - App Association Info
struct AppAssociationInfo {
    var uriSchemes: [String] = []
    var viewerUTIs: [String] = []
    var editorUTIs: [String] = []
    /// Items where this app is the current system default handler
    var defaultURISchemes: Set<String> = []
    var defaultViewerUTIs: Set<String> = []
    var defaultEditorUTIs: Set<String> = []
}

struct ApplicationsView: View {
    @StateObject private var viewModel = ApplicationsViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
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
        VStack(spacing: 0) {
            SearchBar(
                placeholder: "Search applications",
                text: $searchText,
                focused: $isSearchFocused,
                onRefresh: {
                    Task { await viewModel.loadApplications() }
                }
            )

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LuminareDividedStack {
                    appList

                    if let app = selectedApp {
                        AppDetailView(
                            app: app,
                            associations: viewModel.getAssociations(for: app),
                            onReassign: { items, targetApp in
                                viewModel.reassignItems(items, to: targetApp)
                            }
                        )
                    } else {
                        EmptyStateView(icon: "app.dashed", title: "Select an Application")
                            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .background {
            Button("") { isSearchFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .task {
            await viewModel.loadApplications()
        }
    }

    private var appList: some View {
        List(filteredApps) { app in
            AppListRow(app: app, isSelected: selectedApp == app)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedApp = app
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 1, leading: 12, bottom: 1, trailing: 12))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 320, maxWidth: 320, maxHeight: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - App List Row
struct AppListRow: View {
    let app: AppInfo
    let isSelected: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon.resized(to: NSSize(width: 24, height: 24)))
            Text(app.name)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor.opacity(0.6))
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var backgroundColor: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.15))
        } else if isHovering {
            return AnyShapeStyle(.quaternary)
        } else {
            return AnyShapeStyle(.clear)
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

// MARK: - Default Handler Filter
enum DefaultFilter: String, CaseIterable {
    case all = "All"
    case isDefault = "Default"
    case notDefault = "Non-default"
}

// MARK: - App Detail View
struct AppDetailView: View {
    let app: AppInfo
    let associations: AppAssociationInfo
    var onReassign: (Set<SelectableItem>, AppInfo) -> Void = { _, _ in }

    @State private var selectedItems: Set<SelectableItem> = []
    @State private var showingAppPicker = false
    @State private var defaultFilter: DefaultFilter = .all

    // MARK: - Filtered items
    private var filteredURISchemes: [String] {
        switch defaultFilter {
        case .all: return associations.uriSchemes
        case .isDefault:
            return associations.uriSchemes.filter { associations.defaultURISchemes.contains($0) }
        case .notDefault:
            return associations.uriSchemes.filter { !associations.defaultURISchemes.contains($0) }
        }
    }

    private var filteredViewerUTIs: [String] {
        switch defaultFilter {
        case .all: return associations.viewerUTIs
        case .isDefault:
            return associations.viewerUTIs.filter { associations.defaultViewerUTIs.contains($0) }
        case .notDefault:
            return associations.viewerUTIs.filter { !associations.defaultViewerUTIs.contains($0) }
        }
    }

    private var filteredEditorUTIs: [String] {
        switch defaultFilter {
        case .all: return associations.editorUTIs
        case .isDefault:
            return associations.editorUTIs.filter { associations.defaultEditorUTIs.contains($0) }
        case .notDefault:
            return associations.editorUTIs.filter { !associations.defaultEditorUTIs.contains($0) }
        }
    }

    private var hasSelection: Bool {
        !selectedItems.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasSelection {
                selectionToolbar
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    appHeader

                    LuminarePicker(
                        compactElements: DefaultFilter.allCases,
                        selection: $defaultFilter
                    ) { filter in
                        Text(filter.rawValue)
                    }
                    .luminarePickerRoundedCorner(.always)
                    // The knobs' fills are clipped to 2pt corners by the button
                    // style and only the selected knob gets rounded shapes, so
                    // clip the whole control to keep the outer corners rounded.
                    .clipShape(.rect(cornerRadius: 8))
                    .frame(maxWidth: .infinity)

                    uriSchemesSection

                    utisSection
                }
                .padding(20)
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                selectedItems: selectedItems,
                onSelect: { targetApp in
                    onReassign(selectedItems, targetApp)
                    selectedItems.removeAll()
                }
            )
        }
    }

    // MARK: - Sections

    private var appHeader: some View {
        HStack(spacing: 14) {
            Image(nsImage: app.icon.resized(to: NSSize(width: 56, height: 56)))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let version = app.version {
                    Text("Version: \(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let path = app.path {
                Button {
                    NSWorkspace.shared.selectFile(
                        nil, inFileViewerRootedAtPath: path.path)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(path.path)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
            }
        }
    }

    private var uriSchemesSection: some View {
        LuminareSection {
            if associations.uriSchemes.isEmpty {
                Text("No URI schemes registered")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            } else if filteredURISchemes.isEmpty {
                Text("No matching URI schemes")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            } else {
                ForEach(filteredURISchemes, id: \.self) { scheme in
                    SelectableRow(
                        item: .uriScheme(scheme),
                        text: "\(scheme)://",
                        isDefault: associations.defaultURISchemes.contains(scheme),
                        isSelected: selectedItems.contains(.uriScheme(scheme)),
                        onToggle: { toggleSelection(.uriScheme(scheme)) }
                    )
                }
                .padding(.horizontal, 6)
            }
        } header: {
            sectionHeader(
                title: "URI Schemes",
                icon: "link",
                items: filteredURISchemes.map { SelectableItem.uriScheme($0) }
            )
        }
        .luminareHasDividers(false)
    }

    private var utisSection: some View {
        LuminareSection {
            VStack(alignment: .leading, spacing: 16) {
                utiGroup(
                    role: "Viewer",
                    items: filteredViewerUTIs,
                    defaultItems: associations.defaultViewerUTIs,
                    makeItem: { SelectableItem.viewerUTI($0) }
                )

                utiGroup(
                    role: "Editor",
                    items: filteredEditorUTIs,
                    defaultItems: associations.defaultEditorUTIs,
                    makeItem: { SelectableItem.editorUTI($0) }
                )
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        } header: {
            sectionHeader(
                title: "File Types",
                icon: "doc",
                items: filteredViewerUTIs.map { SelectableItem.viewerUTI($0) }
                    + filteredEditorUTIs.map { SelectableItem.editorUTI($0) }
            )
        }
        .luminareHasDividers(false)
    }

    private func utiGroup(
        role: String,
        items: [String],
        defaultItems: Set<String>,
        makeItem: @escaping (String) -> SelectableItem
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(role)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)

                Spacer()

                if !items.isEmpty {
                    Button("Select All") {
                        for uti in items {
                            selectedItems.insert(makeItem(uti))
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)

                    Button("Deselect All") {
                        for uti in items {
                            selectedItems.remove(makeItem(uti))
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .padding(.trailing, 8)
                }
            }

            if items.isEmpty {
                Text("None")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            } else {
                ForEach(items, id: \.self) { uti in
                    SelectableRow(
                        item: makeItem(uti),
                        text: uti,
                        isDefault: defaultItems.contains(uti),
                        isSelected: selectedItems.contains(makeItem(uti)),
                        onToggle: { toggleSelection(makeItem(uti)) }
                    )
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String, items: [SelectableItem]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.medium)
            Spacer()

            if !items.isEmpty {
                Button("Select All") {
                    for item in items {
                        selectedItems.insert(item)
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Deselect All") {
                    for item in items {
                        selectedItems.remove(item)
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .padding(.trailing, 15)
            }
        }
        .padding(.leading, 15)
    }

    private var selectionToolbar: some View {
        HStack {
            Text("\(selectedItems.count) selected")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear") {
                selectedItems.removeAll()
            }
            .buttonStyle(.luminareCompact)
            .fixedSize()

            Button {
                showingAppPicker = true
            } label: {
                Text("Reassign")
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.luminare)
            .fixedSize()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
    }

    private func toggleSelection(_ item: SelectableItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
}

// MARK: - Selectable Row
struct SelectableRow: View {
    let item: SelectableItem
    let text: String
    var isDefault: Bool = false
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isDefault ? "checkmark.circle" : "circle")
                .foregroundStyle(
                    isDefault ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)
                )
                .frame(width: 18)
                .help(
                    isDefault
                        ? "This app is the default handler" : "This app is not the default handler")

            Text(text)
                .font(.system(.body, design: .monospaced))

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundStyle(
                    isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary)
                )
                .frame(width: 18)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .hoverRowHighlight()
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
                .buttonStyle(.luminareCompact)
            }
            .padding()

            Divider()

            SearchBar(placeholder: "Search applications", text: $searchText)

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
                    .hoverRowHighlight()
                    .onTapGesture {
                        onSelect(app)
                        dismiss()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 1, leading: 12, bottom: 1, trailing: 12))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 8)
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
    // Starts `true` so the first frame shows loading, not the empty state.
    @Published var isLoading = true

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

        // Check which items this app is the current default handler for
        var defaultSchemes: Set<String> = []
        for scheme in content.uriSchemes {
            if let handler = lsManager.getDefaultHandler(for: scheme),
                handler.bundleIdentifier == app.bundleIdentifier
            {
                defaultSchemes.insert(scheme)
            }
        }

        var defaultViewerUTIs: Set<String> = []
        for uti in content.viewerUTIs {
            if let handler = lsManager.getDefaultHandler(for: uti, role: .viewer),
                handler.bundleIdentifier == app.bundleIdentifier
            {
                defaultViewerUTIs.insert(uti)
            }
        }

        var defaultEditorUTIs: Set<String> = []
        for uti in content.editorUTIs {
            if let handler = lsManager.getDefaultHandler(for: uti, role: .editor),
                handler.bundleIdentifier == app.bundleIdentifier
            {
                defaultEditorUTIs.insert(uti)
            }
        }

        return AppAssociationInfo(
            uriSchemes: content.uriSchemes,
            viewerUTIs: content.viewerUTIs,
            editorUTIs: content.editorUTIs,
            defaultURISchemes: defaultSchemes,
            defaultViewerUTIs: defaultViewerUTIs,
            defaultEditorUTIs: defaultEditorUTIs
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
    ApplicationsView()
        .frame(width: 900, height: 600)
}
