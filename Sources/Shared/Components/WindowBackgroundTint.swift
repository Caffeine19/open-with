import AppKit
import SwiftUI

/// Tints Luminare's separate window materials without dimming their foreground content.
struct WindowBackgroundTint: NSViewRepresentable {
    var opacity: CGFloat

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Wait until SwiftUI has attached the backgrounds to the window.
        DispatchQueue.main.async { [weak nsView] in
            guard let contentView = nsView?.window?.contentView else { return }
            contentView.layoutSubtreeIfNeeded()
            tintBackgrounds(in: contentView)
        }
    }

    private func tintBackgrounds(in view: NSView) {
        if let background = view as? NSVisualEffectView,
            background.material == .menu,
            background.blendingMode == .behindWindow
        {
            let tint: BackgroundTintView
            if let existing = background.subviews.first(where: { $0 is BackgroundTintView })
                as? BackgroundTintView
            {
                tint = existing
            } else {
                tint = BackgroundTintView(frame: background.bounds)
                tint.autoresizingMask = [.width, .height]
                tint.wantsLayer = true
                background.addSubview(tint)
            }
            tint.layer?.backgroundColor = NSColor.black.withAlphaComponent(opacity).cgColor
        }

        for subview in view.subviews {
            tintBackgrounds(in: subview)
        }
    }
}

private final class BackgroundTintView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
