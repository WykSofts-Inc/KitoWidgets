//
//  KitoWidgetPreviewFrame.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Point sizes and corner radii of each widget family, on a 393-point-wide iPhone (iPhone 15,
/// 16 and 17). Larger phones scale up slightly; the proportions are the same.
public enum KitoWidgetMetrics {
    /// The widget's size in points.
    public static func size(for family: WidgetFamily) -> CGSize {
        switch family {
        case .systemSmall: return CGSize(width: 158, height: 158)
        case .systemMedium: return CGSize(width: 338, height: 158)
        case .systemLarge: return CGSize(width: 338, height: 354)
        case .systemExtraLarge: return CGSize(width: 715, height: 330)
        case .accessoryCircular: return CGSize(width: 72, height: 72)
        case .accessoryRectangular: return CGSize(width: 160, height: 72)
        case .accessoryInline: return CGSize(width: 234, height: 26)
        default: return CGSize(width: 158, height: 158)
        }
    }

    /// The corner radius the Home Screen clips the widget to. 0 for Lock Screen families.
    public static func cornerRadius(for family: WidgetFamily) -> CGFloat {
        family.kitoIsAccessory ? 0 : 22
    }

    /// The default content margin the system adds inside the widget.
    public static func contentMargin(for family: WidgetFamily) -> CGFloat {
        family.kitoIsAccessory ? 0 : 16
    }

    /// A short name, e.g. "Small" or "Lock Screen · Circular".
    public static func name(for family: WidgetFamily) -> String {
        switch family {
        case .systemSmall: return "Small"
        case .systemMedium: return "Medium"
        case .systemLarge: return "Large"
        case .systemExtraLarge: return "Extra large"
        case .accessoryCircular: return "Lock Screen · Circular"
        case .accessoryRectangular: return "Lock Screen · Rectangular"
        case .accessoryInline: return "Lock Screen · Inline"
        default: return "Widget"
        }
    }
}

/// Where a ``KitoWidgetPreviewFrame`` shows its widget.
public enum KitoWidgetPlacement: Hashable, Sendable {
    /// On the Home Screen, with its background.
    case homeScreen
    /// In StandBy: on black, without its background, as the system shows it.
    case standBy
}

/// Renders a widget view in your app at the exact size, margins and corner radius of a family —
/// for galleries, onboarding and previews, without the Home Screen.
///
/// ```swift
/// KitoWidgetPreviewFrame(.systemMedium) {
///     KitoStatWidgetView(title: "Steps", value: 8_432, previous: 7_510, history: week)
/// }
/// ```
///
/// Views inside read the family from the frame, and ``View/kitoWidgetBackground(_:)`` draws its
/// background here, since `containerBackground` only draws inside a real widget. Lock Screen
/// families sit on a wallpaper and render vibrant, as on the Lock Screen.
public struct KitoWidgetPreviewFrame<Content: View>: View {
    public let family: WidgetFamily
    public let placement: KitoWidgetPlacement
    public let showsLabel: Bool
    private let content: Content

    /// - Parameters:
    ///   - family: The size to render at.
    ///   - placement: Home Screen (default) or StandBy.
    ///   - showsLabel: Writes the family's name underneath.
    public init(_ family: WidgetFamily, placement: KitoWidgetPlacement = .homeScreen, showsLabel: Bool = false, @ViewBuilder content: () -> Content) {
        self.family = family
        self.placement = placement
        self.showsLabel = showsLabel
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 8) {
            if family.kitoIsAccessory {
                accessory
            } else {
                system
            }
            if showsLabel {
                Text(KitoWidgetMetrics.name(for: family))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var size: CGSize { KitoWidgetMetrics.size(for: family) }
    private var margin: CGFloat { KitoWidgetMetrics.contentMargin(for: family) }

    private var system: some View {
        let shape = RoundedRectangle(cornerRadius: KitoWidgetMetrics.cornerRadius(for: family), style: .continuous)
        let isStandBy = placement == .standBy
        return content
            .padding(margin)
            .frame(width: size.width, height: size.height)
            .environment(\.kitoWidgetPreview, KitoWidgetPreviewContext(family: family, margin: margin, showsBackground: !isStandBy))
            .background(isStandBy ? Color.black : Color(uiColor: .secondarySystemBackground))
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.primary.opacity(isStandBy ? 0 : 0.06), lineWidth: 1))
            .shadow(color: .black.opacity(isStandBy ? 0 : 0.12), radius: 10, y: 5)
            .environment(\.colorScheme, isStandBy ? .dark : colorScheme)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(KitoWidgetMetrics.name(for: family)) widget"))
    }

    @Environment(\.colorScheme) private var colorScheme

    private var accessory: some View {
        content
            .frame(width: size.width, height: size.height)
            .environment(\.kitoWidgetPreview, KitoWidgetPreviewContext(family: family, margin: 0, showsBackground: false))
            .environment(\.widgetRenderingMode, .vibrant)
            .environment(\.colorScheme, .dark)
            .foregroundStyle(.white)
            .saturation(0)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(KitoLockScreenWallpaper())
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(KitoWidgetMetrics.name(for: family)) widget"))
    }
}

/// A dark, blurred-looking wallpaper for Lock Screen previews.
public struct KitoLockScreenWallpaper: View {
    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.13, green: 0.12, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.12)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(red: 0.55, green: 0.3, blue: 0.9).opacity(0.55), .clear], center: .topTrailing, startRadius: 0, endRadius: 260)
            RadialGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.4), .clear], center: .bottomLeading, startRadius: 0, endRadius: 240)
        }
    }
}
