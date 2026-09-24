import Luminare
import SwiftUI

// MARK: - Pane Scroll Container

/// Scrolling container for settings-style pane content.
struct PaneScrollView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(12)
        }
    }
}

// MARK: - Search Bar

/// A Luminare-styled search field with an optional refresh button.
/// The input flex-grows to fill the row; the button is a fixed square
/// (width == height), both sharing the same `controlHeight`.
struct SearchBar: View {
    static let controlHeight: CGFloat = 32

    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding? = nil
    var onRefresh: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Input: flex-grows, eats everything except the button and spacing.
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .focusedIfPresent(focused)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: Self.controlHeight)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.quaternary)
            }

            // Button: fixed square, width equals height.
            if let onRefresh {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(SearchIconButtonStyle(height: Self.controlHeight))
                .help("Refresh")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Search Icon Button

/// A square icon button whose width is fixed to its height.
struct SearchIconButtonStyle: ButtonStyle {
    var height: CGFloat = 32

    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: height, height: height)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isHovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Empty State

/// Centered placeholder shown when a pane has no data to display.
struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Hover Highlight

/// Rounded hover highlight matching Luminare's list rows.
struct HoverRowHighlight: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .opacity(isHovering ? 1 : 0)
            }
            .onHover { isHovering = $0 }
    }
}

extension View {
    func hoverRowHighlight() -> some View {
        modifier(HoverRowHighlight())
    }

    /// Applies focus tracking when a binding is provided.
    @ViewBuilder
    func focusedIfPresent(_ condition: FocusState<Bool>.Binding?) -> some View {
        if let condition {
            self.focused(condition)
        } else {
            self
        }
    }
}
