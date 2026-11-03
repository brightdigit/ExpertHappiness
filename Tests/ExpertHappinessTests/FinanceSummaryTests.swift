//
//  FinanceSummaryTests.swift
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
internal import Testing

@testable internal import ExpertHappiness

@Suite("Finance summary")
internal struct FinanceSummaryTests {
  private static let columns = [
    "Start Date", "End Date", "Vendor Identifier", "Quantity", "Partner Share",
    "Extended Partner Share", "Partner Share Currency", "Sales or Return", "Title",
    "Country Of Sale",
  ]

  private static let report: String = {
    let rows = [
      columns,
      ["10/04/2026", "10/31/2026", "pro.monthly", "2", "9.34", "18.68", "USD", "S", "Pro", "US"],
      ["10/04/2026", "10/31/2026", "pro.monthly", "-1", "9.34", "-9.34", "USD", "R", "Pro", "US"],
      ["10/04/2026", "10/31/2026", "pro.monthly", "1", "9.06", "9.06", "SEK", "S", "Pro", "SE"],
      [],
      ["Total_Rows", "3"],
      ["Total_Amount", "18.40"],
    ]
    return rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
  }()

  @Test("Nets returns and splits by currency, ignoring footer rows")
  internal func netsReturnsByCurrency() {
    let summary = FinanceSummary(reports: ["2026-10": ReportTable(text: Self.report)])
    #expect(summary.lines.count == 2)
    let sek = summary.lines[0]
    #expect(sek.currency == "SEK")
    #expect(sek.units == 1)
    let usd = summary.lines[1]
    #expect(usd.product == "Pro")
    #expect(usd.currency == "USD")
    #expect(usd.units == 1)
    #expect(usd.proceeds == Decimal(string: "9.34"))
  }
}
