import AppKit
import Luminare

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        setupMainMenu()
        MainWindowController.shared.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    /// Installs a minimal main menu. The Edit menu is required for standard
    /// text editing shortcuts (⌘C, ⌘V, ⌘X, ⌘Z, ⌘A) inside SwiftUI text fields
    /// hosted within NSHostingView.
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu (required for the first menu item)
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(
            NSMenuItem(
                title: "About OpenWith",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            ))
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Hide OpenWith", action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h"))
        let hideOthersItem = NSMenuItem(
            title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(
            NSMenuItem(
                title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit OpenWith", action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        // Edit menu — provides standard text editing shortcuts
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(
            NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(
            NSMenuItem(
                title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(
            NSMenuItem(
                title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)),
                keyEquivalent: "m"))
        windowMenu.addItem(
            NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(
            NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }
}

/// Owns the app's main window, built with Luminare.
final class MainWindowController {
    static let shared = MainWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let luminareWindow = LuminareWindow {
                ContentView()
            }

            luminareWindow.title = "OpenWith"
            // The pane header already names the window content, so keep the
            // title (Dock, Mission Control) but hide it in the titlebar.
            luminareWindow.titleVisibility = .hidden
            // LuminareWindow only styles itself as closable; restore the
            // standard window buttons so the app window behaves normally.
            luminareWindow.styleMask.insert([.miniaturizable, .resizable])
            luminareWindow.contentMinSize = NSSize(width: 880, height: 600)
            luminareWindow.setContentSize(NSSize(width: 1040, height: 720))
            luminareWindow.center()

            window = luminareWindow
        }

        window?.makeKeyAndOrderFront(nil)
    }
}
