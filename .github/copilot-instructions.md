# OpenWith - AI Coding Instructions

When using this instructions, say "⌘ Using copilot-instructions.md" explicitly, this is very very important.

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

## VS Code Tasks

Tasks are defined in `.vscode/tasks.json` and can be run via **Terminal → Run Task…**.

| Label                                  | Description                                                                                                                                                                                             |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Run App** (default build)            | Kills any running instance, builds the `Debug` configuration, packages and ad-hoc signs `OpenWith.app` via `Scripts/package_app.sh debug`, and immediately opens it.                                    |
| **Verify Build**                       | Builds the `Debug` configuration with `swift build` only — use this to confirm the code compiles cleanly.                                                                                               |
| **Release App**                        | Builds the `Release` configuration and packages the ad-hoc signed `OpenWith.app` at the workspace root.                                                                                                 |
| **Publish Release**                    | Prompts for a version, builds the release app bundle, zips it into `dist/`, and creates a GitHub release with the zip attached.                                                                         |
| **Convert ICNS to AppIcon.appiconset** | Prompts for an `.icns` file path, uses `iconutil` to expand it into a temporary `.iconset`, writes the largest PNG as `AppIcon.png` to `Resources/Assets.xcassets/AppIcon.appiconset/`, then cleans up. |

### Run App

```
process       : OpenWith (killed before build)
configuration : Debug (swift build -c debug)
output        : OpenWith.app (workspace root)
opens         : OpenWith.app
```

Trigger with **⇧⌘B** (default build task) or via **Run Task → Run App**.

### Verify Build

```
configuration : Debug (swift build)
```

Run via **Terminal → Run Task → Verify Build**. Does not kill, package, or launch the app.

### Release App

```
configuration : Release (swift build -c release)
output        : OpenWith.app (workspace root, ad-hoc signed)
```

Run via **Terminal → Run Task → Release App**.

### Publish Release

```
input   : version (without v prefix)
builds  : Release app bundle
output  : dist/OpenWith-<version>.zip
creates : GitHub release with tag = version
```

Run via **Terminal → Run Task → Publish Release**. Requires `gh` to be logged in.

### Convert ICNS to AppIcon.appiconset

Requires a valid `.icns` file as input. When the task runs it will prompt:

```
Absolute path to the source .icns file  [default: ${workspaceFolder}/AppIcon.icns]
```

The task uses the macOS `iconutil` CLI to expand the `.icns` into all PNG sizes and writes the largest (`icon_512x512@2x.png`) as `AppIcon.png` in `Resources/Assets.xcassets/AppIcon.appiconset/` — the single source image that `Scripts/package_app.sh` scales to generate `Resources/Icon.icns`.

## Key Decisions

- **macOS 14+** minimum (set in Package.swift)
- **No external dependencies** - pure Swift/SwiftUI/AppKit
- Single flat target structure (all sources in `Sources/`)
- `AppDelegate` used for activation policy (`NSApp.setActivationPolicy(.regular)`)
