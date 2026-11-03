//
//  DateRange.swift
//  ExpertHappiness
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

/// An inclusive range of `yyyy-MM-dd` dates in UTC.
///
/// Defaults: `--to` is today and `--from` is January 1 of `--to`'s year.
internal struct DateRange: Sendable {
  /// How many days after `to` a restated day can still be processed.
  internal static let restatementWindow = 5

  internal static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  internal static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? calendar.timeZone
    return calendar
  }

  internal let start: String
  internal let end: String

  internal init(from start: String?, to end: String?, today: Date = Date()) throws {
    let toDate = try end.map(Self.parse) ?? today
    let year = Self.calendar.component(.year, from: toDate)
    let fromDate =
      try start.map(Self.parse)
      ?? Self.calendar.date(from: DateComponents(year: year, month: 1, day: 1))
      ?? toDate
    guard fromDate <= toDate else {
      throw CLIError.invalid("--from must not be after --to.")
    }
    self.start = Self.formatter.string(from: fromDate)
    self.end = Self.formatter.string(from: toDate)
  }

  /// Processing dates to fetch: `from` through `to` plus the restatement
  /// window, capped at today.
  internal func processingDates(today: Date = Date()) -> [String] {
    guard let first = Self.formatter.date(from: start), let lastDay = Self.formatter.date(from: end)
    else {
      return []
    }
    let padded =
      Self.calendar.date(byAdding: .day, value: Self.restatementWindow, to: lastDay) ?? lastDay
    let last = min(padded, today)
    var dates: [String] = []
    var day = first
    while day <= last {
      dates.append(Self.formatter.string(from: day))
      guard let next = Self.calendar.date(byAdding: .day, value: 1, to: day) else {
        break
      }
      day = next
    }
    return dates
  }
}

extension DateRange {
  fileprivate static func parse(_ text: String) throws -> Date {
    guard let date = formatter.date(from: text) else {
      throw CLIError.invalid("Dates must look like 2026-09-27; got \(text).")
    }
    return date
  }
}
