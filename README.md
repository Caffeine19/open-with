# OpenWith

A modern macOS SwiftUI application for managing default applications for URL schemes and file types.

## Features

- **Internet Services**: Manage default browser, email client, FTP client, and RSS reader
- **URI Schemes**: View and modify all registered URL scheme handlers
- **File Types**: Manage default applications for file types (UTIs)
- **Applications**: Browse all installed applications and their associations

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
Sources/
├── App/
│   ├── OpenWithApp.swift              # App entry point
│   └── ContentView.swift              # Main navigation view
├── Core/
│   ├── LaunchServicesManager.swift    # Launch Services API wrapper
│   ├── AppInfo.swift                  # Application model
│   └── Errors.swift                   # Error types
├── Features/
│   ├── Internet/                      # Internet schemes management
│   ├── URISchemes/                    # All URI schemes
│   ├── FileTypes/                     # File type (UTI) management
│   └── Applications/                  # Application browser
└── Shared/
    ├── Components/                    # Reusable UI components
    └── Extensions/                    # Swift extensions
```

## Building

### Using Swift Package Manager

```bash
swift build
swift run OpenWith
```

### Using Xcode

1. Open `Package.swift` in Xcode
2. Select the `OpenWith` scheme
3. Build and run (⌘R)

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Views**: SwiftUI views for UI rendering
- **ViewModels**: `@MainActor` classes managing state and business logic
- **Models**: Data structures like `AppInfo`
- **Services**: `LaunchServicesManager` for system API interactions

## APIs Used

The app uses macOS Launch Services APIs:

- `LSCopyDefaultHandlerForURLScheme` - Get default URL scheme handler
- `LSCopyAllHandlersForURLScheme` - Get all registered handlers
- `LSSetDefaultHandlerForURLScheme` - Set default URL scheme handler
- `LSCopyDefaultRoleHandlerForContentType` - Get default UTI handler
- `LSCopyAllRoleHandlersForContentType` - Get all UTI handlers
- `LSSetDefaultRoleHandlerForContentType` - Set default UTI handler

## License

MIT License
