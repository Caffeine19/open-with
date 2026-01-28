import SwiftUI

/// A picker component for selecting applications
struct AppPicker: View {
    let title: String
    @Binding var selectedApp: AppInfo?
    let availableApps: [AppInfo]
    let onSelect: (AppInfo) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
            
            Picker("", selection: Binding(
                get: { selectedApp },
                set: { newValue in
                    if let app = newValue {
                        onSelect(app)
                    }
                }
            )) {
                if availableApps.isEmpty {
                    Text("No apps available")
                        .tag(nil as AppInfo?)
                } else {
                    ForEach(availableApps) { app in
                        HStack {
                            Image(nsImage: app.icon.resized(to: NSSize(width: 14, height: 14)))
                            Text(app.name)
                        }
                        .tag(app as AppInfo?)
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AppPicker_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            AppPicker(
                title: "Browser",
                selectedApp: .constant(nil),
                availableApps: [],
                onSelect: { _ in }
            )
        }
        .formStyle(.grouped)
        .frame(width: 400)
    }
}
