import SwiftUI

struct URISchemesView: View {
    @StateObject private var viewModel = URISchemesViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var filteredSchemes: [URISchemeItem] {
        if searchText.isEmpty {
            return viewModel.schemes
        }
        return viewModel.schemes.filter {
            $0.scheme.localizedCaseInsensitiveContains(searchText)
                || ($0.handler?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Search schemes", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)
                Button {
                    Task { await viewModel.loadSchemes() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if viewModel.isLoading {
                ProgressView("Loading URI schemes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.schemes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No URI Schemes Found")
                        .font(.title2)
                    Text("Unable to load registered URI schemes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredSchemes) { item in
                    URISchemeRow(item: item, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("URI Schemes")
        .background {
            Button("") { isSearchFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .task {
            await viewModel.loadSchemes()
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

struct URISchemeRow: View {
    let item: URISchemeItem
    @ObservedObject var viewModel: URISchemesViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Scheme icon
            Image(systemName: "link")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.scheme + "://")
                    .font(.headline)
                    .fontDesign(.monospaced)

                if let handler = item.handler {
                    HStack(spacing: 4) {
                        Image(nsImage: handler.icon.resized(to: NSSize(width: 12, height: 12)))
                        Text(handler.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No handler")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // App picker
            if !item.availableHandlers.isEmpty {
                Picker(
                    "",
                    selection: Binding(
                        get: { item.handler },
                        set: { newApp in
                            if let app = newApp {
                                viewModel.setHandler(app, for: item.scheme)
                            }
                        }
                    )
                ) {
                    ForEach(item.availableHandlers) { app in
                        HStack {
                            Image(nsImage: app.icon.resized(to: NSSize(width: 12, height: 12)))
                            Text(app.name)
                        }
                        .tag(app as AppInfo?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        URISchemesView()
    }
    .frame(width: 700, height: 500)
}
