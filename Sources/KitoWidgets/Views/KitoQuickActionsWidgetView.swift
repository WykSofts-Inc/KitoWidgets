//
//  KitoQuickActionsWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A grid of shortcut tiles. `.perform` tiles run an intent in place; `.open` tiles open your app
/// at a URL (in the small size, where links aren't allowed, through ``KitoOpenDeepLinkIntent``).
///
/// ```swift
/// KitoQuickActionsWidgetView(actions: [
///     KitoQuickAction(title: "Water", symbol: "drop.fill", tint: .cyan, action: .perform(KitoIncrementCounterIntent())),
///     KitoQuickAction(title: "Scan", symbol: "qrcode.viewfinder", tint: .orange, action: .open(scanURL)),
/// ])
/// ```
public struct KitoQuickActionsWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .accessoryCircular]

    let title: String?
    let actions: [KitoQuickAction]
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: A header for the medium and large sizes.
    ///   - actions: Up to 4 show in small, 8 in medium, 9 in large; the Lock Screen shows the first.
    ///   - background: The gradient behind the tiles.
    public init(title: String? = nil, actions: [KitoQuickAction], background: KitoWidgetGradient = .graphite) {
        self.title = title
        self.actions = actions
        self.background = background
    }

    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(title ?? "Quick actions"))
    }

    @ViewBuilder private var content: some View {
        switch traits.family {
        case .accessoryCircular: circular
        case .systemMedium: medium
        case .systemLarge, .systemExtraLarge: large
        default: small
        }
    }

    // MARK: Tiles

    @ViewBuilder private func tile(_ item: KitoQuickAction, showsTitle: Bool, corner: CGFloat) -> some View {
        let label = tileLabel(item, showsTitle: showsTitle, corner: corner)
        switch item.action {
        case .open(let url):
            if traits.family == .systemSmall {
                Button(intent: KitoOpenDeepLinkIntent(url: url)) { label }.buttonStyle(.plain)
            } else {
                Link(destination: url) { label }
            }
        case .perform(let intent):
            Button(intent: intent) { label }.buttonStyle(.plain)
        }
    }

    private func tileLabel(_ item: KitoQuickAction, showsTitle: Bool, corner: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: item.symbol)
                .font(.system(size: showsTitle ? 17 : 20, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
            if showsTitle {
                Spacer(minLength: 2)
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showsTitle ? .topLeading : .center)
        .padding(showsTitle ? 10 : 0)
        .background {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(LinearGradient(colors: [item.tint.opacity(0.95), item.tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .widgetAccentable()
        }
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(.isButton)
    }

    private func grid(_ items: ArraySlice<KitoQuickAction>, columns: Int, spacing: CGFloat, showsTitle: Bool, corner: CGFloat,
                      rowHeight: CGFloat? = nil) -> some View {
        let rows = stride(from: items.startIndex, to: items.endIndex, by: columns).map { start in
            Array(items[start..<min(start + columns, items.endIndex)])
        }
        return VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row) { item in tile(item, showsTitle: showsTitle, corner: corner) }
                    ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear }
                }
                .frame(height: rowHeight)
            }
        }
    }

    private var header: some View {
        Group {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Layouts

    private var small: some View {
        grid(actions.prefix(4), columns: 2, spacing: 8, showsTitle: false, corner: 16)
    }

    private var medium: some View {
        VStack(spacing: 8) {
            if actions.count <= 4 {
                header
                grid(actions.prefix(4), columns: 4, spacing: 8, showsTitle: true, corner: 16)
            } else {
                grid(actions.prefix(8), columns: 4, spacing: 8, showsTitle: false, corner: 14)
            }
        }
    }

    private var large: some View {
        VStack(spacing: 10) {
            header
            grid(actions.prefix(9), columns: 3, spacing: 10, showsTitle: true, corner: 18, rowHeight: 88)
            Spacer(minLength: 0)
        }
    }

    // MARK: Lock Screen

    @ViewBuilder private var circular: some View {
        if let first = actions.first {
            let label = ZStack {
                KitoAccessoryBackdrop()
                Image(systemName: first.symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .widgetAccentable()
            }
            .accessibilityLabel(Text(first.title))
            switch first.action {
            case .open(let url):
                label.widgetURL(url)
            case .perform(let intent):
                Button(intent: intent) { label }.buttonStyle(.plain)
            }
        }
    }
}
