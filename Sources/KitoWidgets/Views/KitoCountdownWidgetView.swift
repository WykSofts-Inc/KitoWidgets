//
//  KitoCountdownWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A countdown to a date that ticks on its own — the system redraws `Text` timers and
/// `ProgressView(timerInterval:)` every second, so no timeline reloads are needed.
///
/// Days away it shows a day count and a relative date; inside the final stretch (24 hours by
/// default) a live timer; then "Happening now" until `end`, then done. Give your timeline an entry
/// at each of ``KitoCountdown/transitionDates(after:target:end:finalStretch:)`` so it switches on time.
///
/// ```swift
/// KitoCountdownWidgetView(title: "Launch", target: launch, start: announced, now: entry.date)
/// ```
public struct KitoCountdownWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let target: Date
    let start: Date?
    let end: Date?
    let symbol: String
    let tint: Color
    let background: KitoWidgetGradient
    let now: Date
    let finalStretch: TimeInterval
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: The event, e.g. "Launch".
    ///   - target: When it starts.
    ///   - start: When the countdown began; draws a progress bar filling towards `target`.
    ///   - end: When the event is over. Without it, the countdown is done at `target`.
    ///   - symbol: An SF Symbol for the header.
    ///   - tint: The accent for bars and the date card.
    ///   - background: The gradient behind it.
    ///   - now: The entry's date. Pass `entry.date` in a widget.
    ///   - finalStretch: How long before `target` the ticking timer appears.
    public init(title: String, target: Date, start: Date? = nil, end: Date? = nil, symbol: String = "timer",
                tint: Color = .orange, background: KitoWidgetGradient = .sunset, now: Date = Date(),
                finalStretch: TimeInterval = KitoCountdown.defaultFinalStretch) {
        self.title = title
        self.target = target
        self.start = start
        self.end = end
        self.symbol = symbol
        self.tint = tint
        self.background = background
        self.now = now
        self.finalStretch = finalStretch
    }

    private var phase: KitoCountdownPhase {
        KitoCountdown.phase(at: now, target: target, end: end, finalStretch: finalStretch)
    }
    private var days: Int { KitoCountdown.daysRemaining(from: now, to: target) }
    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var elapsedFraction: Double {
        guard let start, target > start else { return 0 }
        return KitoProgress.fraction(now.timeIntervalSince(start), of: target.timeIntervalSince(start))
    }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(accessibilityValue))
    }

    private var accessibilityValue: String {
        switch phase {
        case .upcoming: return "\(days) days to go, \(target.formatted(date: .complete, time: .shortened))"
        case .finalStretch: return "\(KitoCountdown.shortText(from: now, to: target)) to go"
        case .live: return "Happening now"
        case .ended: return "Finished"
        }
    }

    @ViewBuilder private var content: some View {
        switch traits.family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        case .systemLarge, .systemExtraLarge: large
        default: small
        }
    }

    // MARK: Pieces

    /// The main readout for the current phase.
    @ViewBuilder private func readout(size: CGFloat) -> some View {
        switch phase {
        case .upcoming:
            VStack(alignment: .leading, spacing: -2) {
                Text("\(days)")
                    .font(.system(size: size * 1.5, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText(value: Double(days)))
                Text(days == 1 ? "day to go" : "days to go")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.75))
            }
        case .finalStretch:
            VStack(alignment: .leading, spacing: 0) {
                Text(timerInterval: now...max(target, now), countsDown: true)
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                Text("to go")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.75))
            }
        case .live:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 9, height: 9).widgetAccentable()
                    Text("Happening now")
                        .font(.system(size: size * 0.62, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                if let end {
                    Text("Ends in \(Text(timerInterval: now...max(end, now), countsDown: true))")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(foreground.opacity(0.75))
                        .monospacedDigit()
                }
            }
        case .ended:
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: size * 0.9, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .widgetAccentable()
                Text("That's a wrap")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            }
        }
    }

    /// A ticking relative line ("in 2 days, 4 hours") or the date once it's passed.
    @ViewBuilder private var footnote: some View {
        switch phase {
        case .upcoming, .finalStretch:
            Text(target, style: .relative)
                .font(.caption2.weight(.medium))
                .foregroundStyle(foreground.opacity(0.65))
                .lineLimit(1)
        case .live, .ended:
            Text(target, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
                .font(.caption2.weight(.medium))
                .foregroundStyle(foreground.opacity(0.65))
                .lineLimit(1)
        }
    }

    @ViewBuilder private var bar: some View {
        if let start, target > start, phase == .upcoming || phase == .finalStretch {
            if traits.isPreview {
                KitoProgressBar(fraction: elapsedFraction, color: tint, height: 5)
            } else {
                ProgressView(timerInterval: start...target, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                    .progressViewStyle(.linear)
                    .tint(tint)
            }
        }
    }

    private var dateCard: some View {
        VStack(spacing: 0) {
            Text(target, format: .dateTime.month(.abbreviated))
                .font(.system(size: 12, weight: .heavy))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(tint.gradient)
                .widgetAccentable()
            Text(target, format: .dateTime.day())
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
                .frame(maxHeight: .infinity)
            Text(target, format: .dateTime.weekday(.wide))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(foreground.opacity(0.65))
                .padding(.bottom, 8)
        }
        .frame(width: 92)
        .background(foreground.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// The centre of the large size's ring.
    @ViewBuilder private var ringCenter: some View {
        VStack(spacing: 0) {
            switch phase {
            case .upcoming:
                Text("\(days)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText(value: Double(days)))
                Text(days == 1 ? "day to go" : "days to go").font(.system(size: 12, weight: .semibold)).opacity(0.75)
            case .finalStretch:
                Text(timerInterval: now...max(target, now), countsDown: true)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("to go").font(.system(size: 12, weight: .semibold)).opacity(0.75)
            case .live:
                HStack(spacing: 5) {
                    Circle().fill(Color.red).frame(width: 8, height: 8).widgetAccentable()
                    Text("LIVE").font(.system(size: 13, weight: .heavy))
                }
                if let end {
                    Text(timerInterval: now...max(end, now), countsDown: true)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("left").font(.system(size: 12, weight: .semibold)).opacity(0.75)
                } else {
                    Text("Now").font(.system(size: 30, weight: .heavy, design: .rounded))
                }
            case .ended:
                Image(systemName: "checkmark").font(.system(size: 36, weight: .bold)).widgetAccentable()
                Text("Done").font(.system(size: 14, weight: .bold))
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: foreground, foreground: foreground)
            Spacer(minLength: 2)
            readout(size: 30)
                .foregroundStyle(foreground)
            Spacer(minLength: 4)
            bar
            footnote.padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                KitoWidgetHeader(symbol: symbol, title: title, tint: foreground, foreground: foreground)
                Spacer(minLength: 2)
                readout(size: 32)
                    .foregroundStyle(foreground)
                Spacer(minLength: 4)
                bar
                footnote.padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            dateCard
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 14) {
            KitoWidgetHeader(symbol: symbol, title: "Countdown", tint: foreground, foreground: foreground)
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(target, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(foreground.opacity(0.7))
                }
                Spacer(minLength: 0)
                dateCard.frame(height: 104)
            }
            ZStack {
                KitoRingView(laps: phase == .ended || phase == .live ? 1 : elapsedFraction, color: foreground,
                             lineWidth: 16, trackOpacity: 0.18)
                ringCenter
                    .foregroundStyle(foreground)
                    .frame(width: 132)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footnote.frame(maxWidth: .infinity)
        }
    }

    // MARK: Lock Screen

    @ViewBuilder private var circular: some View {
        switch phase {
        case .upcoming:
            ZStack {
                KitoAccessoryBackdrop()
                VStack(spacing: -3) {
                    Text("\(days)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: Double(days)))
                    Text(days == 1 ? "DAY" : "DAYS").font(.system(size: 9, weight: .heavy))
                }
            }
        case .finalStretch:
            let ringStart = start ?? target.addingTimeInterval(-finalStretch)
            if ringStart < target, !traits.isPreview {
                ProgressView(timerInterval: ringStart...target, countsDown: false) {
                    Image(systemName: symbol)
                } currentValueLabel: {
                    Image(systemName: symbol)
                }
                .progressViewStyle(.circular)
                .widgetAccentable()
            } else {
                ZStack {
                    KitoAccessoryBackdrop()
                    KitoRingView(laps: KitoProgress.fraction(now.timeIntervalSince(ringStart), of: target.timeIntervalSince(ringStart)),
                                 color: .white, lineWidth: 5, trackOpacity: 0.25).padding(3)
                    VStack(spacing: 0) {
                        Image(systemName: symbol).font(.system(size: 11, weight: .bold))
                        Text(KitoCountdown.shortText(from: now, to: target))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6)
                    }
                    .padding(8)
                }
            }
        case .live:
            ZStack {
                KitoAccessoryBackdrop()
                VStack(spacing: 1) {
                    Image(systemName: symbol).font(.system(size: 16, weight: .bold)).widgetAccentable()
                    Text("LIVE").font(.system(size: 10, weight: .heavy))
                }
            }
        case .ended:
            ZStack {
                KitoAccessoryBackdrop()
                Image(systemName: "checkmark").font(.system(size: 24, weight: .bold)).widgetAccentable()
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .widgetAccentable()
            switch phase {
            case .upcoming:
                Text("\(days) \(days == 1 ? "day" : "days")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: Double(days)))
                Text(target, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    .font(.system(size: 12, weight: .medium)).opacity(0.75)
            case .finalStretch:
                Text(timerInterval: now...max(target, now), countsDown: true)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                bar
            case .live:
                Text("Happening now").font(.system(size: 17, weight: .bold, design: .rounded))
                if let end {
                    Text("Ends in \(Text(timerInterval: now...max(end, now), countsDown: true))")
                        .font(.system(size: 12, weight: .medium)).opacity(0.75)
                }
            case .ended:
                Text("That's a wrap").font(.system(size: 17, weight: .bold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var inline: some View {
        switch phase {
        case .upcoming:
            Label("\(title) in \(days)d", systemImage: symbol)
        case .finalStretch:
            Label {
                Text("\(title) \(Text(timerInterval: now...max(target, now), countsDown: true))")
            } icon: {
                Image(systemName: symbol)
            }
        case .live:
            Label("\(title) · now", systemImage: symbol)
        case .ended:
            Label("\(title) · done", systemImage: "checkmark")
        }
    }
}
