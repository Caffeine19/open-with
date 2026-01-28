import SwiftUI

struct InternetSchemesView: View {
    @StateObject private var viewModel = InternetSchemesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading internet services...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section("Web Browser") {
                        AppPicker(
                            title: "HTTP/HTTPS",
                            selectedApp: $viewModel.defaultBrowser,
                            availableApps: viewModel.browserApps,
                            onSelect: { app in
                                viewModel.setDefaultBrowser(app)
                            }
                        )
                    }
                    
                    Section("Email Client") {
                        AppPicker(
                            title: "mailto:",
                            selectedApp: $viewModel.defaultMailClient,
                            availableApps: viewModel.mailApps,
                            onSelect: { app in
                                viewModel.setDefaultMailClient(app)
                            }
                        )
                    }
                    
                    Section("Other Protocols") {
                        AppPicker(
                            title: "FTP",
                            selectedApp: $viewModel.defaultFTP,
                            availableApps: viewModel.ftpApps,
                            onSelect: { app in
                                viewModel.setDefaultFTP(app)
                            }
                        )
                        
                        AppPicker(
                            title: "RSS",
                            selectedApp: $viewModel.defaultRSS,
                            availableApps: viewModel.rssApps,
                            onSelect: { app in
                                viewModel.setDefaultRSS(app)
                            }
                        )
                    }
                }
                .formStyle(.grouped)
            }
        }
        .navigationTitle("Internet Services")
        .task {
            await viewModel.loadData()
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

#Preview {
    NavigationStack {
        InternetSchemesView()
    }
    .frame(width: 600, height: 500)
}
