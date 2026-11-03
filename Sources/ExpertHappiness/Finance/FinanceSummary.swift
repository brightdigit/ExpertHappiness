//
//  FinanceSummary.swift
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

public import Foundation

/// Proceeds per month, per product and per currency, from finance reports.
public struct FinanceSummary: Sendable {
  /// One month's proceeds for one product in one currency.
  public struct Line: Sendable, Equatable {
    /// The month the report is keyed by, `yyyy-MM`.
    public let month: String
    /// The product's title, or its vendor identifier when there's no title.
    public let product: String
    /// The currency Apple paid in.
    public let currency: String
    /// Units sold, net of returns.
    public let units: Int
    /// Extended partner share (proceeds), net of returns.
    public let proceeds: Decimal
  }

  /// Every line, sorted by month, product, then currency.
  public let lines: [Line]

  /// Builds a summary from finance-detail reports keyed by month.
  ///
  /// Rows missing the quantity or partner-share columns are skipped.
  /// Apple's footer rows ("Total", "Country Of Sale" …) have no quantity, so
  /// they drop out too.
  public init(reports: [String: ReportTable]) {
    struct Key: Hashable {
      let month: String
      let product: String
      let currency: String
    }
    var units: [Key: Int] = [:]
    var proceeds: [Key: Decimal] = [:]
    for (month, table) in reports {
      for row in table.rows {
        guard
          let quantity = Self.firstValue(row, ["Quantity"]).flatMap({ Int($0) }),
          let share = Self.firstValue(row, ["Extended Partner Share"])
            .flatMap({ Decimal(string: $0) })
        else {
          continue
        }
        let product =
          Self.firstValue(row, ["Title", "Vendor Identifier", "SKU"]) ?? "Unknown"
        let currency =
          Self.firstValue(row, ["Partner Share Currency", "Currency of Proceeds"]) ?? "?"
        let key = Key(month: month, product: product, currency: currency)
        units[key, default: 0] += quantity
        proceeds[key, default: 0] += share
      }
    }
    lines = proceeds.keys
      .map { key in
        Line(
          month: key.month,
          product: key.product,
          currency: key.currency,
          units: units[key] ?? 0,
          proceeds: proceeds[key] ?? 0
        )
      }
      .sorted { lhs, rhs in
        (lhs.month, lhs.product, lhs.currency) < (rhs.month, rhs.product, rhs.currency)
      }
  }

  private static func firstValue(_ row: [String: String], _ columns: [String]) -> String? {
    for column in columns {
      if let value = row[column]?.trimmingCharacters(in: .whitespaces), !value.isEmpty {
        return value
      }
    }
    return nil
  }
}
