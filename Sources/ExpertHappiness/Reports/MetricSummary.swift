//
//  MetricSummary.swift
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

/// Totals from one report, grouped per a ``SummarySpec``.
public struct MetricSummary: Sendable, Equatable {
  /// A group and its totals.
  public struct Row: Sendable, Equatable {
    /// The group-by values.
    public let group: [String]
    /// The summed values, matching ``MetricSummary/valueColumns``.
    public let totals: [Decimal]
  }

  /// The spec's title.
  public let title: String
  /// The report the totals came from.
  public let reportName: String
  /// The group-by columns that were present.
  public let groupColumns: [String]
  /// The value columns that were present.
  public let valueColumns: [String]
  /// One row per group: the group's values, then the totals, in column order.
  public let rows: [Row]
  /// Spec columns the report didn't have.
  public let missingColumns: [String]
  /// How many source rows were totaled.
  public let sourceRowCount: Int

  /// Totals a report table.
  public init(spec: SummarySpec, reportName: String, table: ReportTable) {
    let present = Set(table.columns)
    let groupColumns = spec.groupBy.filter(present.contains)
    let valueColumns =
      spec.values.isEmpty
      ? Self.numericColumns(of: table, excluding: Set(groupColumns))
      : spec.values.filter(present.contains)
    var sourceRows = table.rows
    if spec.latestDateOnly,
      let latest = sourceRows.compactMap({ $0[ReportArchive.dateColumn] }).max()
    {
      sourceRows = sourceRows.filter { $0[ReportArchive.dateColumn] == latest }
    }
    var totals: [[String]: [Decimal]] = [:]
    for row in sourceRows {
      let key = groupColumns.map { row[$0] ?? "" }
      var sums = totals[key] ?? Array(repeating: 0, count: valueColumns.count)
      for (index, column) in valueColumns.enumerated() {
        sums[index] += Decimal(string: row[column] ?? "") ?? 0
      }
      totals[key] = sums
    }
    self.title = spec.title
    self.reportName = reportName
    self.groupColumns = groupColumns
    self.valueColumns = valueColumns
    self.rows = totals.map { Row(group: $0.key, totals: $0.value) }
      .sorted { $0.group.lexicographicallyPrecedes($1.group) }
    // A value column is only "missing" when none of the candidates exist.
    self.missingColumns =
      spec.groupBy.filter { !present.contains($0) } + (valueColumns.isEmpty ? spec.values : [])
    self.sourceRowCount = sourceRows.count
  }

  /// Columns whose non-empty values all parse as numbers, other than the
  /// date column, the group-by columns and ID-like columns.
  private static func numericColumns(of table: ReportTable, excluding: Set<String>) -> [String] {
    table.columns.filter { column in
      guard column != ReportArchive.dateColumn, !excluding.contains(column),
        !column.hasSuffix("ID"), !column.localizedCaseInsensitiveContains("identifier")
      else {
        return false
      }
      let values = table.rows.compactMap { $0[column] }.filter { !$0.isEmpty }
      return !values.isEmpty && values.allSatisfy { Double($0) != nil }
    }
  }

  /// The summary as a Markdown table, ready to paste into notes.
  public func markdown() -> String {
    var lines = ["### \(title)", "", "_Report: \(reportName), \(sourceRowCount) rows_", ""]
    let header = groupColumns + valueColumns
    if header.isEmpty || rows.isEmpty {
      lines.append("No data.")
    } else {
      lines.append("| " + header.joined(separator: " | ") + " |")
      lines.append("|" + header.map { _ in "---" }.joined(separator: "|") + "|")
      for row in rows {
        let values = row.totals.map { NSDecimalNumber(decimal: $0).stringValue }
        lines.append("| " + (row.group + values).joined(separator: " | ") + " |")
      }
    }
    if !missingColumns.isEmpty {
      lines.append("")
      lines.append("_Columns not in this report: \(missingColumns.joined(separator: ", "))_")
    }
    return lines.joined(separator: "\n")
  }
}
