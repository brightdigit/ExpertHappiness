//
//  MonthRange.swift
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

/// An inclusive range of `yyyy-MM` months.
///
/// Defaults to the last 12 complete months: `--to-month` is last month and
/// `--from-month` is 11 months before it.
internal struct MonthRange: Sendable {
  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM"
    return formatter
  }()

  internal let months: [String]

  internal init(from start: String?, to end: String?, today: Date = Date()) throws {
    let endDate = try end.map(Self.parse) ?? Self.shift(Self.monthStart(of: today), by: -1)
    let startDate = try start.map(Self.parse) ?? Self.shift(endDate, by: -11)
    guard startDate <= endDate else {
      throw CLIError.invalid("--from-month is after --to-month")
    }
    var months: [String] = []
    var cursor = startDate
    while cursor <= endDate {
      months.append(Self.formatter.string(from: cursor))
      cursor = try Self.shift(cursor, by: 1)
    }
    self.months = months
  }

  private static func parse(_ text: String) throws -> Date {
    guard let date = formatter.date(from: text) else {
      throw CLIError.invalid("\(text) isn't a yyyy-MM month")
    }
    return date
  }

  private static func monthStart(of date: Date) throws -> Date {
    let calendar = DateRange.calendar
    guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
    else {
      throw CLIError.invalid("couldn't work out the current month")
    }
    return start
  }

  private static func shift(_ date: Date, by months: Int) throws -> Date {
    guard let shifted = DateRange.calendar.date(byAdding: .month, value: months, to: date) else {
      throw CLIError.invalid("couldn't shift a month by \(months)")
    }
    return shifted
  }
}
