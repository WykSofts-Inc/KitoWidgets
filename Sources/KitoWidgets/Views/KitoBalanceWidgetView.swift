//
//  KitoBalanceWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// An account balance with today's change, a trend and recent transactions.
///
/// Amounts hide themselves when the user asks (`isHidden`), on the Always-On display
/// (`isLuminanceReduced`), and when the system redacts private content on a locked device —
/// they're marked `privacySensitive()`.
///
/// ```swift
/// KitoBalanceWidgetView(balance: 12_480.5, currencyCode: "KES", change: 2_300, history: month)
/// ```
public struct KitoBalanceWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let balance: Double
    let currencyCode: String
    let change: Double?
    let history: [Double]
    let accountSuffix: String?
    let transactions: [KitoBalanceTransaction]
    let isHidden: Bool
    let symbol: String
    let tint: Color
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: The account, e.g. "Everyday".
    ///   - balance: The available balance.
    ///   - currencyCode: ISO 4217, e.g. "KES" or "USD".
    ///   - change: Today's change; positive is money in.
    ///   - history: Recent balances, oldest first.
    ///   - accountSuffix: The last digits, shown as "•••• 4821".
    ///   - transactions: The latest few, for the large size.
    ///   - isHidden: Hide every amount, e.g. from an in-app privacy setting.
    ///   - symbol: An SF Symbol for the account.
    ///   - tint: The accent for the trend line.
    ///   - background: The gradient behind it.
    public init(title: String = "Balance", balance: Double, currencyCode: String, change: Double? = nil,
                history: [Double] = [], accountSuffix: String? = nil, transactions: [KitoBalanceTransaction] = [],
                isHidden: Bool = false, symbol: String = "creditcard.fill", tint: Color = .mint,
                background: KitoWidgetGradient = .midnight) {
        self.title = title
        self.balance = balance
        self.currencyCode = currencyCode
        self.change = change
        self.history = history
        self.accountSuffix = accountSuffix
        self.transactions = transactions
        self.isHidden = isHidden
        self.symbol = symbol
        self.tint = tint
        self.background = background
    }

    /// Whether amounts are hidden right now.
    private var hidesAmounts: Bool {
        isHidden || traits.isLuminanceReduced || traits.redactionReasons.contains(.privacy)
    }
    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var money: KitoStatFormat { .currency(code: currencyCode) }
    private var positive: Color { Color(red: 0.36, green: 0.93, blue: 0.6) }
    private var negative: Color { Color(red: 1, green: 0.5, blue: 0.5) }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(hidesAmounts ? "Balance hidden" : money.string(for: balance)))
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

    /// The amount, or a masked placeholder when hidden.
    private func amount(_ value: Double, size: CGFloat, format: KitoStatFormat? = nil) -> some View {
        ZStack(alignment: .leading) {
            Text((format ?? money).string(for: value))
                .opacity(hidesAmounts ? 0 : 1)
                .contentTransition(.numericText(value: value))
            if hidesAmounts {
                HStack(spacing: 5) {
                    Text(currencyCode)
                    Text("••••••").tracking(1)
                }
                .transition(.opacity)
            }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .privacySensitive()
        .animation(.smooth(duration: 0.3), value: hidesAmounts)
        .animation(.snappy, value: value)
    }

    private var accountRow: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(background.colors.first ?? .black)
                .frame(width: 24, height: 24)
                .background(Circle().fill(foreground))
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                if let accountSuffix {
                    Text("•••• \(accountSuffix)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(foreground.opacity(0.55))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var changeLine: some View {
        if let change {
            HStack(spacing: 3) {
                Image(systemName: change >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                    .font(.system(size: 9, weight: .heavy))
                Text(hidesAmounts ? "Today" : "\(change >= 0 ? "+" : "−")\(money.string(for: abs(change))) today")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(change >= 0 ? positive : negative)
            .privacySensitive()
        }
    }

    private var balanceBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Available")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(foreground.opacity(0.6))
            amount(balance, size: 26)
                .foregroundStyle(foreground)
            changeLine
        }
    }

    private var trend: some View {
        KitoSparklineView(values: history, tint: tint, lineWidth: 2.4)
            .blur(radius: hidesAmounts ? 6 : 0)
            .opacity(hidesAmounts ? 0.5 : 1)
            .animation(.smooth, value: hidesAmounts)
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            accountRow
            Spacer(minLength: 4)
            balanceBlock
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                accountRow
                Spacer(minLength: 4)
                balanceBlock
            }
            .frame(width: 150)
            if !history.isEmpty {
                trend.padding(.vertical, 8)
            }
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            accountRow
            balanceBlock
            if !history.isEmpty {
                trend.frame(height: transactions.isEmpty ? 150 : 56)
            }
            if !transactions.isEmpty {
                Text("RECENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(foreground.opacity(0.55))
                VStack(spacing: 9) {
                    ForEach(transactions.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(foreground)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(foreground.opacity(0.12)))
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(foreground)
                                    .lineLimit(1)
                                Text(item.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                                    .font(.system(size: 10))
                                    .foregroundStyle(foreground.opacity(0.55))
                            }
                            Spacer(minLength: 4)
                            Text(hidesAmounts ? "•••" : "\(item.amount >= 0 ? "+" : "−")\(money.string(for: abs(item.amount)))")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(item.amount >= 0 ? positive : foreground)
                                .lineLimit(1)
                                .privacySensitive()
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            KitoAccessoryBackdrop()
            VStack(spacing: 1) {
                Image(systemName: hidesAmounts ? "lock.fill" : symbol)
                    .font(.system(size: 12, weight: .bold))
                    .widgetAccentable()
                if !hidesAmounts {
                    Text(KitoStatFormat.compact.string(for: balance))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .privacySensitive()
                }
            }
            .padding(6)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .widgetAccentable()
            amount(balance, size: 21)
            if let change, !hidesAmounts {
                Text("\(change >= 0 ? "+" : "−")\(money.string(for: abs(change))) today")
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.75)
                    .lineLimit(1)
                    .privacySensitive()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label(hidesAmounts ? "\(title) ••••" : "\(title) \(KitoStatFormat.compact.string(for: balance)) \(currencyCode)",
              systemImage: symbol)
    }
}
