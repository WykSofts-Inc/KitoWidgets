//
//  KitoQuoteWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A quote of the day, set in serif over a gradient or a photo with a dark scrim.
///
/// ```swift
/// KitoQuoteWidgetView(quote: "Simplicity is the soul of efficiency.", author: "Austin Freeman")
/// ```
public struct KitoQuoteWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline,
    ]

    let quote: String
    let author: String?
    let photo: Image?
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - quote: The text, without quotation marks.
    ///   - author: Who said it.
    ///   - photo: An optional full-bleed photo; a scrim keeps the text readable.
    ///   - background: The gradient when there's no photo.
    public init(quote: String, author: String? = nil, photo: Image? = nil, background: KitoWidgetGradient = .grape) {
        self.quote = quote
        self.author = author
        self.photo = photo
        self.background = background
    }

    private var foreground: Color {
        photo != nil ? .white : (traits.showsBackground ? background.foreground : .primary)
    }

    private var quoteSize: CGFloat {
        switch traits.family {
        case .systemMedium: return 19
        case .systemLarge, .systemExtraLarge: return 28
        default: return 16
        }
    }

    public var body: some View {
        Group {
            if let photo {
                content.kitoWidgetBackground { KitoPhotoScrim(photo: photo) }
            } else {
                content.kitoWidgetBackground(background)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(author.map { "\(quote), \($0)" } ?? quote))
    }

    @ViewBuilder private var content: some View {
        switch traits.family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(quote).font(.system(size: 13, weight: .medium, design: .serif)).lineLimit(3)
                if let author { Text(author).font(.system(size: 11, weight: .semibold)).opacity(0.7) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Label(quote, systemImage: "quote.opening")
        default:
            home
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.system(size: traits.isLarge ? 30 : 18, weight: .black))
                .foregroundStyle(foreground.opacity(0.45))
                .widgetAccentable()
            Spacer(minLength: 0)
            Text(quote)
                .font(.system(size: quoteSize, weight: .semibold, design: .serif))
                .foregroundStyle(foreground)
                .lineLimit(traits.isLarge ? 8 : (traits.family == .systemMedium ? 4 : 5))
                .minimumScaleFactor(0.6)
                .shadow(color: photo != nil ? .black.opacity(0.4) : .clear, radius: 6, y: 1)
                .contentTransition(.opacity)
            if let author {
                HStack(spacing: 6) {
                    Capsule().fill(foreground.opacity(0.6)).frame(width: 14, height: 2)
                    Text(author)
                        .font(.system(size: traits.isLarge ? 14 : 11, weight: .semibold))
                        .foregroundStyle(foreground.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            if photo == nil {
                Image(systemName: "quote.closing")
                    .font(.system(size: traits.isLarge ? 150 : 90, weight: .black))
                    .foregroundStyle(foreground.opacity(0.07))
                    .offset(x: 18, y: -12)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A photo with a caption over a gradient scrim — memories, featured places, the day's pick.
///
/// ```swift
/// KitoPhotoWidgetView(photo: Image("coast"), title: "Diani Beach", subtitle: "One year ago")
/// ```
public struct KitoPhotoWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]

    let photo: Image
    let title: String
    let subtitle: String?
    let badge: String?
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - photo: The full-bleed image. Decode it to about the widget's size — widgets have a
    ///     tight memory limit.
    ///   - title: The caption.
    ///   - subtitle: A second line, e.g. a date.
    ///   - badge: A small chip at the top, e.g. "Memories".
    public init(photo: Image, title: String, subtitle: String? = nil, badge: String? = nil) {
        self.photo = photo
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let badge {
                Text(badge.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
                    .environment(\.colorScheme, .dark)
            }
            Spacer(minLength: 0)
            Text(title)
                .font(.system(size: traits.isLarge ? 26 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: traits.isLarge ? 14 : 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .kitoWidgetBackground { KitoPhotoScrim(photo: photo) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text([title, subtitle].compactMap { $0 }.joined(separator: ", ")))
        .accessibilityAddTraits(.isImage)
    }
}

/// A photo filling the widget with a dark gradient at the bottom for text.
struct KitoPhotoScrim: View {
    let photo: Image

    var body: some View {
        ZStack {
            photo
                .resizable()
                .scaledToFill()
            LinearGradient(stops: [
                .init(color: .black.opacity(0.25), location: 0),
                .init(color: .clear, location: 0.3),
                .init(color: .black.opacity(0.2), location: 0.55),
                .init(color: .black.opacity(0.72), location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }
}
