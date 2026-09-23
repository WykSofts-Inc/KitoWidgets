//
//  KitoWidgetEnvironment.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// What a ``KitoWidgetPreviewFrame`` tells the views inside it, since WidgetKit's own
/// `widgetFamily` can't be set outside a widget.
struct KitoWidgetPreviewContext: Equatable {
    var family: WidgetFamily
    var margin: CGFloat
    var showsBackground: Bool
}

private struct KitoWidgetPreviewKey: EnvironmentKey {
    static let defaultValue: KitoWidgetPreviewContext? = nil
}

extension EnvironmentValues {
    var kitoWidgetPreview: KitoWidgetPreviewContext? {
        get { self[KitoWidgetPreviewKey.self] }
        set { self[KitoWidgetPreviewKey.self] = newValue }
    }
}

extension WidgetFamily {
    /// Lock Screen (and watch) families.
    var kitoIsAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
        default: return false
        }
    }
}

/// The widget traits a view needs, resolved the same way in a real widget and in a preview frame.
struct KitoWidgetTraits: DynamicProperty {
    @Environment(\.widgetFamily) private var systemFamily
    @Environment(\.kitoWidgetPreview) private var preview
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.showsWidgetContainerBackground) private var systemShowsBackground
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @Environment(\.redactionReasons) var redactionReasons

    var family: WidgetFamily { preview?.family ?? systemFamily }
    var isPreview: Bool { preview != nil }
    var isAccessory: Bool { family.kitoIsAccessory }
    /// Lock Screen style: the system maps content to one tint, so use white and opacity.
    var isVibrant: Bool { renderingMode == .vibrant }
    /// Tinted Home Screen: only `widgetAccentable` content takes the tint.
    var isAccented: Bool { renderingMode == .accented }
    /// False in StandBy and the tinted and clear Home Screens, where the system removes it.
    var showsBackground: Bool { preview?.showsBackground ?? systemShowsBackground }
    var isLarge: Bool { family == .systemLarge || family == .systemExtraLarge }
}

// MARK: - Shared pieces

/// A Lock Screen widget's translucent backing. `AccessoryWidgetBackground` only draws in a real
/// widget, so previews draw a matching shape.
struct KitoAccessoryBackdrop: View {
    var circular = true
    @Environment(\.kitoWidgetPreview) private var preview

    var body: some View {
        if preview != nil {
            if circular {
                Circle().fill(.white.opacity(0.16))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.16))
            }
        } else {
            AccessoryWidgetBackground()
        }
    }
}

/// The small symbol + title line at the top of most widgets.
struct KitoWidgetHeader: View {
    let symbol: String?
    let title: String
    let tint: Color
    var foreground: Color = .white
    var trailing: String?

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .widgetAccentable()
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foreground.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(foreground.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A trimmed ring with a gradient stroke. `laps` above 1 draws a second lap on top.
struct KitoRingView: View {
    let laps: Double
    let color: Color
    let lineWidth: CGFloat
    var trackOpacity: Double = 0.22

    var body: some View {
        let first = min(max(laps, 0), 1)
        let second = min(max(laps - 1, 0), 1)
        ZStack {
            Circle()
                .stroke(color.opacity(trackOpacity), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: first)
                .stroke(AngularGradient(colors: [color.opacity(0.7), color], center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(360 * max(first, 0.01))),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .widgetAccentable()
            if second > 0 {
                Circle()
                    .trim(from: 0, to: second)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: .black.opacity(0.35), radius: lineWidth / 3)
                    .widgetAccentable()
            }
        }
        .rotationEffect(.degrees(-90))
        .padding(lineWidth / 2)
    }
}

/// An arrow and percentage for a stat's change.
struct KitoDeltaBadge: View {
    let delta: KitoStatDelta
    var increaseIsGood = true
    var format: KitoStatFormat = .number()
    var compact = false

    private var color: Color {
        switch delta.direction {
        case .flat: return .white.opacity(0.7)
        case .up: return increaseIsGood ? Color(red: 0.36, green: 0.93, blue: 0.6) : Color(red: 1, green: 0.45, blue: 0.45)
        case .down: return increaseIsGood ? Color(red: 1, green: 0.45, blue: 0.45) : Color(red: 0.36, green: 0.93, blue: 0.6)
        }
    }

    private var symbol: String {
        switch delta.direction {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: compact ? 9 : 10, weight: .heavy))
            Text(delta.text(format: format))
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, compact ? 0 : 7)
        .padding(.vertical, compact ? 0 : 3)
        .background {
            if !compact { Capsule().fill(color.opacity(0.18)) }
        }
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        switch delta.direction {
        case .up: return "Up \(delta.text(format: format))"
        case .down: return "Down \(delta.text(format: format))"
        case .flat: return "No change"
        }
    }
}
