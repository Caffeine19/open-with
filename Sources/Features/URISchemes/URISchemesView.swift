import Luminare
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
            SearchBar(
                placeholder: "Search schemes",
                text: $searchText,
                focused: $isSearchFocused,
                onRefresh: {
                    Task { await viewModel.loadSchemes() }
                }
            )

            if viewModel.isLoading {
                ProgressView("Loading URI schemes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.schemes.isEmpty {
                EmptyStateView(
                    icon: "link.circle",
                    title: "No URI Schemes Found",
                    message: "Unable to load registered URI schemes"
                )
            } else {
                List(filteredSchemes) { item in
                    URISchemeRow(item: item, viewModel: viewModel)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 1, leading: 12, bottom: 1, trailing: 12))
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
            Image(systemName: "link")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(item.scheme + "://")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)

            Spacer()

            AppMenuPicker(
                apps: item.availableHandlers,
                selection: item.handler,
                onCommit: { app in
                    if let app {
                        viewModel.setHandler(app, for: item.scheme)
                    }
                }
            )
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .hoverRowHighlight()
    }
}

#Preview {
    URISchemesView()
        .frame(width: 700, height: 500)
}
