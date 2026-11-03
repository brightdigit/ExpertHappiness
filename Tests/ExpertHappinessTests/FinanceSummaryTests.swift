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

  /// The layout of a real FINANCE_DETAIL file: preamble, header, rows, then a
  /// per-country summary with its own header and no blank line between.
  private static let financeDetail: String = {
    let rows = [
      ["Vendor Name", "EXAMPLE LLC"],
      ["Start Date", "02/01/2026"],
      ["End Date", "02/28/2026"],
      [
        "Transaction Date", "Settlement Date", "Apple Identifier", "SKU", "Title",
        "Developer Name", "Product Type Identifier", "Country of Sale", "Quantity",
        "Partner Share", "Extended Partner Share", "Partner Share Currency",
      ],
      [
        "02/10/2026", "02/14/2026", "1", "pro.monthly", "Pro Monthly", "", "IAY", "US", "1", "9.34",
        "9.34", "USD",
      ],
      [
        "02/11/2026", "02/12/2026", "1", "pro.monthly", "Pro Monthly", "", "IAY", "US", "1", "9.34",
        "9.34", "USD",
      ],
      [
        "02/16/2026", "02/17/2026", "2", "pro.yearly", "Pro Yearly", "", "IAY", "SE", "1", "98.60",
        "98.60", "SEK",
      ],
      ["Country Of Sale", "Partner Share Currency", "Quantity", "Extended Partner Share"],
      ["US", "USD", "2", "18.68"],
      ["SE", "SEK", "1", "98.60"],
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

  @Test("Skips the finance report preamble and per-country summary")
  internal func parsesFinanceDetailLayout() {
    let table = ReportTable(financeReport: Self.financeDetail)
    #expect(table.columns.first == "Transaction Date")
    let summary = FinanceSummary(reports: ["2026-05": table])
    #expect(summary.lines.count == 2)
    #expect(summary.lines[0].product == "Pro Monthly")
    #expect(summary.lines[0].units == 2)
    #expect(summary.lines[0].proceeds == Decimal(string: "18.68"))
    #expect(summary.lines[1].product == "Pro Yearly")
    #expect(summary.lines[1].currency == "SEK")
  }

  @Test("Calendar months map to Apple's fiscal months")
  internal func fiscalMonths() {
    #expect(FiscalMonth(calendarMonth: "2026-10")?.reportDate == "2027-01")
    #expect(FiscalMonth(calendarMonth: "2026-12")?.reportDate == "2027-03")
    #expect(FiscalMonth(calendarMonth: "2026-01")?.reportDate == "2026-04")
    #expect(FiscalMonth(calendarMonth: "2026-09")?.reportDate == "2026-12")
    #expect(FiscalMonth(calendarMonth: "2026-13") == nil)
    #expect(FiscalMonth(calendarMonth: "October") == nil)
  }

  @Test("Reads the report period from the preamble")
  internal func reportPeriod() {
    let period = FinanceReportPeriod(financeReport: Self.financeDetail)
    #expect(period?.start == "02/01/2026")
    #expect(period?.end == "02/28/2026")
    #expect(FinanceReportPeriod(financeReport: Self.report) == nil)
  }
}
