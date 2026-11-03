//
//  ReportTable+Finance.swift
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

extension ReportTable {
  /// Parses a finance report, which doesn't start with its header row.
  ///
  /// Apple's finance reports open with a few `name<TAB>value` lines (vendor
  /// name, start date, end date) before the column header, so this starts
  /// at the first line that has a `Quantity` column. The per-country summary
  /// at the end has only four columns, so its rows have no `Quantity` value
  /// and ``FinanceSummary`` skips them. Text with no such line parses as usual.
  ///
  /// - Parameter text: The report text.
  public init(financeReport text: String) {
    let lines = text.split(whereSeparator: \.isNewline)
    guard
      let start = lines.firstIndex(where: { line in
        line.split(separator: "\t").contains {
          $0.trimmingCharacters(in: .whitespaces) == "Quantity"
        }
      })
    else {
      self.init(text: text)
      return
    }
    self.init(text: lines[start...].joined(separator: "\n"))
  }
}
