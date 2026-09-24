import AppKit

// AppKit entry point: the whole UI lives in a single `LuminareWindow`,
// created by `MainWindowController` during `applicationDidFinishLaunching`.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
