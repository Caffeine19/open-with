import AppKit

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        guard targetSize.width > 0, targetSize.height > 0 else { return self }
        let image = NSImage(size: targetSize)
        image.lockFocus()
        defer { image.unlockFocus() }
        let rect = NSRect(origin: .zero, size: targetSize)
        self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        image.isTemplate = self.isTemplate
        return image
    }
}
