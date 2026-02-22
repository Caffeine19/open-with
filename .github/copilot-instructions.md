# OpenWith - AI Coding Instructions

## Project Overview
A macOS SwiftUI application for managing default app handlers for URL schemes (http, mailto, etc.) and file types (UTIs). Uses private Launch Services APIs to query and modify system defaults.

## Architecture

### MVVM Pattern with `@MainActor`
- **ViewModels**: Always use `@MainActor class` with `@Published` properties and `ObservableObject`
- **Views**: Use `@StateObject` to own ViewModels, `@ObservedObject` when passed as dependency
- **Data loading**: Use `.task { await viewModel.loadData() }` modifier, call `await Task.yield()` before heavy work to allow UI updates

### Key Components
- `LaunchServicesManager` ([Sources/Core/LaunchServicesManager.swift](../Sources/Core/LaunchServicesManager.swift)): Singleton (`shared`) wrapping macOS Launch Services APIs. All system interactions go through here.
- `AppInfo` ([Sources/Core/AppInfo.swift](../Sources/Core/AppInfo.swift)): Failable initializer from bundle identifier - returns `nil` if app not found.

### Feature Organization
```
Sources/Features/{FeatureName}/
├── {FeatureName}View.swift       # SwiftUI view
└── {FeatureName}ViewModel.swift  # State management (if needed)
```

## Code Conventions

### ViewModel Pattern
```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var showError = false
    var lastError: Error?
    
    private let lsManager = LaunchServicesManager.shared
    
    func loadData() async {
        isLoading = true
        await Task.yield()  // Always yield before heavy work
        // ... load data
        isLoading = false
    }
}
```

### Error Handling
- ViewModels expose `showError: Bool` and `lastError: Error?` for alert presentation
- Views use `.alert("Error", isPresented: $viewModel.showError)` pattern
- Errors are defined in [Sources/Core/Errors.swift](../Sources/Core/Errors.swift) as `LocalizedError` enums

### Private APIs
Uses `@_silgen_name` to access undocumented Launch Services functions:
- `_LSCopySchemesAndHandlerURLs` - discovers all registered URL schemes
- `_UTCopyDeclaredTypeIdentifiers` - discovers all declared UTIs

## Build Commands
```bash
swift build                        # Debug build
swift build -c release             # Release build
swift run OpenWith                 # Run directly
./Scripts/package_app.sh           # Create .app bundle (release)
./Scripts/package_app.sh debug     # Create .app bundle (debug)
```

## Key Decisions
- **macOS 14+** minimum (set in Package.swift)
- **No external dependencies** - pure Swift/SwiftUI/AppKit
- Single flat target structure (all sources in `Sources/`)
- `AppDelegate` used for activation policy (`NSApp.setActivationPolicy(.regular)`)
