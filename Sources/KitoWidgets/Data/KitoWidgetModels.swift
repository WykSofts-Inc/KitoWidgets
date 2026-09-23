//
//  KitoWidgetModels.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import AppIntents

// MARK: - Tasks

/// A to-do or agenda item shown by ``KitoListWidgetView``.
public struct KitoWidgetTask: Codable, Hashable, Identifiable, Sendable {
    /// The store key the built-in task intent uses unless told otherwise.
    public static let defaultStoreKey = "kito.widgets.tasks"

    public var id: String
    public var title: String
    /// A secondary line, e.g. a list name or location.
    public var detail: String?
    /// Shown as a time on agenda-style rows.
    public var due: Date?
    public var isDone: Bool

    public init(id: String = UUID().uuidString, title: String, detail: String? = nil, due: Date? = nil, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.due = due
        self.isDone = isDone
    }
}

extension Array where Element == KitoWidgetTask {
    /// Flips the task with `id`, returning its new state, or `nil` if there's no such task.
    @discardableResult
    public mutating func toggle(id: String) -> Bool? {
        guard let index = firstIndex(where: { $0.id == id }) else { return nil }
        self[index].isDone.toggle()
        return self[index].isDone
    }

    /// How many tasks are done.
    public var completedCount: Int { filter(\.isDone).count }

    /// The done fraction, 0 for an empty list.
    public var completionFraction: Double {
        isEmpty ? 0 : Double(completedCount) / Double(count)
    }

    /// Open tasks first (keeping their order), then done ones.
    public var openFirst: [KitoWidgetTask] { filter { !$0.isDone } + filter(\.isDone) }
}

// MARK: - Counter

/// A daily counter, e.g. glasses of water. It starts again from zero each calendar day.
public struct KitoWidgetCounter: Codable, Hashable, Sendable {
    /// The store key the built-in counter intent uses unless told otherwise.
    public static let defaultStoreKey = "kito.widgets.counter"

    public var count: Int
    public var goal: Int
    /// What's being counted, e.g. "glasses".
    public var unit: String
    /// The start of the day `count` belongs to.
    public var day: Date

    public init(count: Int = 0, goal: Int = 8, unit: String = "glasses", day: Date = Calendar.current.startOfDay(for: Date())) {
        self.count = max(count, 0)
        self.goal = max(goal, 1)
        self.unit = unit
        self.day = day
    }

    /// This counter as of `now`: the same counter today, or zeroed on a later day.
    public func current(at now: Date = Date(), calendar: Calendar = .current) -> KitoWidgetCounter {
        guard !calendar.isDate(day, inSameDayAs: now) else { return self }
        var fresh = self
        fresh.count = 0
        fresh.day = calendar.startOfDay(for: now)
        return fresh
    }

    /// Adds `amount` (negative to undo), resetting first if the day has changed. Never below 0.
    public mutating func increment(by amount: Int = 1, at now: Date = Date(), calendar: Calendar = .current) {
        self = current(at: now, calendar: calendar)
        count = max(count + amount, 0)
    }

    /// `count / goal`, clamped to 0...1.
    public var progress: Double { KitoProgress.fraction(Double(count), of: Double(goal)) }
    /// Whether the goal is reached.
    public var isComplete: Bool { count >= goal }
}

// MARK: - Rings

/// One ring of ``KitoProgressRingWidgetView``.
public struct KitoRing: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var value: Double
    public var goal: Double
    /// Written after the numbers, e.g. "kcal" or "min".
    public var unit: String
    public var color: Color
    public var symbol: String?

    public init(id: String? = nil, title: String, value: Double, goal: Double, unit: String = "", color: Color, symbol: String? = nil) {
        self.id = id ?? title
        self.title = title
        self.value = value
        self.goal = goal
        self.unit = unit
        self.color = color
        self.symbol = symbol
    }

    /// Progress clamped to 0...1.
    public var progress: Double { KitoProgress.fraction(value, of: goal) }
    /// Progress up to two laps, for drawing past the goal.
    public var laps: Double { KitoProgress.ratio(value, of: goal, maxLaps: 2) }
}

// MARK: - Weather

/// One hour in ``KitoWeatherStyleWidgetView``'s strip.
public struct KitoHourlyForecast: Identifiable, Hashable, Sendable {
    public var id: Date { date }
    public var date: Date
    /// An SF Symbol, e.g. "cloud.sun.fill".
    public var symbol: String
    public var temperature: Double
    /// 0...1, shown when above 0.2.
    public var precipitationChance: Double

    public init(date: Date, symbol: String, temperature: Double, precipitationChance: Double = 0) {
        self.date = date
        self.symbol = symbol
        self.temperature = temperature
        self.precipitationChance = precipitationChance
    }
}

// MARK: - Finance

/// A recent transaction in ``KitoBalanceWidgetView``'s large size.
public struct KitoBalanceTransaction: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    /// Negative for money out.
    public var amount: Double
    public var symbol: String
    public var date: Date

    public init(id: String = UUID().uuidString, title: String, amount: Double, symbol: String = "creditcard.fill", date: Date = Date()) {
        self.id = id
        self.title = title
        self.amount = amount
        self.symbol = symbol
        self.date = date
    }
}

// MARK: - Quick actions

/// A tile in ``KitoQuickActionsWidgetView``.
public struct KitoQuickAction: Identifiable {
    /// What tapping the tile does.
    public enum Action {
        /// Opens your app at a URL (handle it in `.onOpenURL`).
        case open(URL)
        /// Runs an intent in place without opening the app (interactive widgets, iOS 17).
        case perform(any AppIntent)
    }

    public var id: String
    public var title: String
    public var symbol: String
    public var tint: Color
    public var action: Action

    public init(id: String? = nil, title: String, symbol: String, tint: Color, action: Action) {
        self.id = id ?? title
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.action = action
    }
}
