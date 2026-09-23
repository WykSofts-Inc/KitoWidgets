//
//  KitoWidgetBackground.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A widget background: a gradient with a soft highlight, plus the colour text sits in on top.
public struct KitoWidgetGradient: Hashable, Sendable {
    public var colors: [Color]
    public var startPoint: UnitPoint
    public var endPoint: UnitPoint
    /// The colour for text and symbols on this background.
    public var foreground: Color
    /// How strong the top-leading highlight is, 0...1.
    public var glow: Double

    public init(colors: [Color], startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing,
                foreground: Color = .white, glow: Double = 0.28) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.foreground = foreground
        self.glow = glow
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    /// Near-black indigo. The default.
    public static let midnight = KitoWidgetGradient(colors: [rgb(0x1E1B4B), rgb(0x0B0B1A)], glow: 0.22)
    /// Coral into violet.
    public static let sunset = KitoWidgetGradient(colors: [rgb(0xFF7A59), rgb(0xE0457B), rgb(0x7B2FF7)])
    /// Sky into deep blue.
    public static let ocean = KitoWidgetGradient(colors: [rgb(0x38BDF8), rgb(0x2563EB), rgb(0x1E3A8A)])
    /// Teal, green and indigo, like the northern lights.
    public static let aurora = KitoWidgetGradient(colors: [rgb(0x34D399), rgb(0x0EA5A4), rgb(0x3730A3)], startPoint: .top, endPoint: .bottomTrailing)
    /// Fresh green.
    public static let mint = KitoWidgetGradient(colors: [rgb(0x4ADE80), rgb(0x0F9D76)])
    /// Amber into red.
    public static let ember = KitoWidgetGradient(colors: [rgb(0xFBBF24), rgb(0xF97316), rgb(0xDC2626)])
    /// Purple into magenta.
    public static let grape = KitoWidgetGradient(colors: [rgb(0xA855F7), rgb(0x6D28D9), rgb(0x4C1D95)])
    /// Pink into rose.
    public static let blossom = KitoWidgetGradient(colors: [rgb(0xF9A8D4), rgb(0xEC4899), rgb(0xBE185D)])
    /// Charcoal.
    public static let graphite = KitoWidgetGradient(colors: [rgb(0x3F3F46), rgb(0x18181B)], glow: 0.18)
    /// Follows the system: white in light mode, black in dark, with primary text.
    public static let system = KitoWidgetGradient(colors: [Color(uiColor: .secondarySystemBackground), Color(uiColor: .systemBackground)],
                                                  startPoint: .top, endPoint: .bottom, foreground: .primary, glow: 0)

    /// Every preset, for pickers.
    public static let presets: [(name: String, gradient: KitoWidgetGradient)] = [
        ("Midnight", .midnight), ("Sunset", .sunset), ("Ocean", .ocean), ("Aurora", .aurora), ("Mint", .mint),
        ("Ember", .ember), ("Grape", .grape), ("Blossom", .blossom), ("Graphite", .graphite), ("System", .system),
    ]
}

/// Draws a ``KitoWidgetGradient``: the gradient, a soft highlight, and a slight dim in dark mode.
public struct KitoWidgetBackground: View {
    public let gradient: KitoWidgetGradient
    @Environment(\.colorScheme) private var colorScheme

    public init(_ gradient: KitoWidgetGradient = .midnight) {
        self.gradient = gradient
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: gradient.colors, startPoint: gradient.startPoint, endPoint: gradient.endPoint)
            if gradient.glow > 0 {
                RadialGradient(colors: [.white.opacity(gradient.glow), .clear], center: .topLeading, startRadius: 0, endRadius: 220)
                    .blendMode(.softLight)
                RadialGradient(colors: [.black.opacity(0.25), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 260)
            }
            if colorScheme == .dark && gradient.glow > 0 {
                Color.black.opacity(0.12)
            }
        }
    }
}

extension View {
    /// Sets a gradient preset as the widget's container background. In a
    /// ``KitoWidgetPreviewFrame`` it's drawn behind the content, so in-app previews match.
    public func kitoWidgetBackground(_ gradient: KitoWidgetGradient = .midnight) -> some View {
        modifier(KitoWidgetBackgroundModifier(background: KitoWidgetBackground(gradient)))
    }

    /// Sets any view, e.g. a photo, as the widget's container background.
    public func kitoWidgetBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        modifier(KitoWidgetBackgroundModifier(background: background()))
    }
}

private struct KitoWidgetBackgroundModifier<Background: View>: ViewModifier {
    let background: Background
    @Environment(\.kitoWidgetPreview) private var preview
    private var traits = KitoWidgetTraits()

    init(background: Background) {
        self.background = background
    }

    func body(content: Content) -> some View {
        content
            .containerBackground(for: .widget) {
                // The Lock Screen draws no background; each accessory view adds its own backdrop.
                if traits.isAccessory { Color.clear } else { background }
            }
            .background {
                if let preview, preview.showsBackground, !preview.family.kitoIsAccessory {
                    background.padding(-preview.margin)
                }
            }
    }
}
