//
//  FiscalMonth.swift
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

/// Apple's fiscal month, which finance reports use as their `reportDate`.
///
/// Apple's fiscal year starts at the end of September, so fiscal month 1 of
/// 2027 is (roughly) October 2026. Each fiscal month ends on a Saturday, so
/// its dates don't match the calendar month exactly; a report's preamble
/// gives the real range (see ``FinanceReportPeriod``).
public struct FiscalMonth: Sendable, Equatable, Hashable {
  /// The fiscal year.
  public let year: Int
  /// The fiscal month, 1 (October) to 12 (September).
  public let month: Int

  /// The `yyyy-MM` value Apple expects for `reportDate`.
  public var reportDate: String {
    String(format: "%04d-%02d", year, month)
  }

  /// The fiscal month that mostly overlaps a calendar month.
  ///
  /// - Parameters:
  ///   - calendarYear: The calendar year.
  ///   - calendarMonth: The calendar month, 1–12.
  public init(calendarYear: Int, calendarMonth: Int) {
    if calendarMonth >= 10 {
      year = calendarYear + 1
      month = calendarMonth - 9
    } else {
      year = calendarYear
      month = calendarMonth + 3
    }
  }

  /// The fiscal month for a calendar month written as `yyyy-MM`, or `nil`
  /// when the text isn't one.
  ///
  /// - Parameter calendarMonth: A calendar month such as `2026-10`.
  public init?(calendarMonth: String) {
    let parts = calendarMonth.split(separator: "-")
    guard
      parts.count == 2,
      let year = Int(parts[0]),
      let month = Int(parts[1]),
      (1...12).contains(month)
    else {
      return nil
    }
    self.init(calendarYear: year, calendarMonth: month)
  }
}
