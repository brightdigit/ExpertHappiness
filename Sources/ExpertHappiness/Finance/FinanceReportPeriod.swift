//
//  FinanceReportPeriod.swift
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

/// The date range a finance report covers, from its preamble.
///
/// Finance reports open with `Start Date` and `End Date` lines, in Apple's
/// `MM/dd/yyyy` format, before the column header.
public struct FinanceReportPeriod: Sendable, Equatable {
  /// The first day covered, as Apple writes it (`MM/dd/yyyy`).
  public let start: String
  /// The last day covered, as Apple writes it (`MM/dd/yyyy`).
  public let end: String

  /// Reads the period from a report's preamble, or fails when either date
  /// line is missing.
  ///
  /// - Parameter text: The report text.
  public init?(financeReport text: String) {
    var values: [String: String] = [:]
    for line in text.split(whereSeparator: \.isNewline).prefix(10) {
      let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard fields.count >= 2 else {
        continue
      }
      let name = fields[0].trimmingCharacters(in: .whitespaces)
      if name == "Start Date" || name == "End Date" {
        values[name] = fields[1].trimmingCharacters(in: .whitespaces)
      }
    }
    guard let start = values["Start Date"], let end = values["End Date"] else {
      return nil
    }
    self.start = start
    self.end = end
  }
}
