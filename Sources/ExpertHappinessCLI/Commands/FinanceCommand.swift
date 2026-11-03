//
//  FinanceCommand.swift
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

internal import ExpertHappiness
internal import Foundation

/// Downloads monthly finance reports and prints proceeds per month and product.
internal struct FinanceCommand: ExpertHappinessCommand {
  internal static let commandName = "finance"
  internal static let abstract = "Download monthly finance reports and total the proceeds"
  internal static let helpText = """
    FINANCE - Monthly proceeds from App Store Connect finance reports

    USAGE:
      expert-happiness finance [--from-month yyyy-MM] [--to-month yyyy-MM]

    OPTIONS:
      --vendor <number>       Vendor number, or ASC_VENDOR_NUMBER
      --from-month <yyyy-MM>  First calendar month (default: 11 before --to-month)
      --to-month <yyyy-MM>    Last calendar month (default: last month)
      --output <dir>          Where reports are saved (default: Reports)

    The vendor number is shown at the top of Payments and Financial Reports.

    Months are calendar months. Apple files finance reports by fiscal month,
    and its fiscal year starts in late September, so October 2026 is fiscal
    2027-01. Fiscal months end on a Saturday, so each one's real dates are
    printed in the Period column.

    Saves each month's FINANCE_DETAIL report to <output>/finance/<fiscal>.tsv,
    named by fiscal month and skipping months already on disk, then prints
    proceeds per month, product and currency as Markdown. Months Apple hasn't
    published are listed, not treated as errors.

    Finance reports need a key with the Admin or Finance role.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  private static func markdown(
    _ summary: FinanceSummary,
    periods: [String: FinanceReportPeriod]
  ) -> String {
    var lines = [
      "| Month | Period | Product | Currency | Units | Proceeds |",
      "|---|---|---|---|---:|---:|",
    ]
    for line in summary.lines {
      let period = periods[line.month].map { "\($0.start)–\($0.end)" } ?? ""
      lines.append(
        "| \(line.month) | \(period) | \(line.product) | \(line.currency) | \(line.units) "
          + "| \(line.proceeds) |"
      )
    }
    return lines.joined(separator: "\n")
  }

  /// Reads a cached report, or downloads and caches it.
  private static func report(
    at file: URL,
    fiscal: FiscalMonth,
    vendorNumber: String,
    service: AnalyticsService
  ) async throws -> String? {
    if FileManager.default.fileExists(atPath: file.path) {
      return try String(contentsOf: file, encoding: .utf8)
    }
    let text = try await service.financeReport(
      vendorNumber: vendorNumber,
      month: fiscal.reportDate
    )
    if let text {
      try text.write(to: file, atomically: true, encoding: .utf8)
    }
    return text
  }

  internal func execute() async throws {
    guard let vendorNumber = config.vendorNumber, !vendorNumber.isEmpty else {
      throw CLIError.missing(
        "ASC_VENDOR_NUMBER (or --vendor), shown at the top of Payments and Financial Reports"
      )
    }
    let range = try MonthRange(from: config.fromMonth, to: config.toMonth)
    let directory = config.output.appendingPathComponent("finance", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let service = try config.makeService()

    var reports: [String: ReportTable] = [:]
    var periods: [String: FinanceReportPeriod] = [:]
    var missing: [String] = []
    for month in range.months {
      guard let fiscal = FiscalMonth(calendarMonth: month) else {
        throw CLIError.invalid("\(month) isn't a yyyy-MM month")
      }
      let file = directory.appendingPathComponent("\(fiscal.reportDate).tsv")
      if let text = try await Self.report(
        at: file,
        fiscal: fiscal,
        vendorNumber: vendorNumber,
        service: service
      ) {
        reports[month] = ReportTable(financeReport: text)
        periods[month] = FinanceReportPeriod(financeReport: text)
      } else {
        missing.append("\(month) (fiscal \(fiscal.reportDate))")
      }
    }
    print(Self.markdown(FinanceSummary(reports: reports), periods: periods))
    if !missing.isEmpty {
      print("\nNo report from Apple for: \(missing.joined(separator: ", "))")
    }
  }
}
