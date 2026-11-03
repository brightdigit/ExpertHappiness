//
//  ReportArchive.swift
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

/// The on-disk layout for downloaded segments:
/// `<root>/<app>/<report name>/<processingDate>-<segment>.tsv`.
public struct ReportArchive: Sendable {
  /// The column holding each row's data date.
  public static let dateColumn = "Date"

  /// The archive's root directory.
  public let root: URL

  /// Creates an archive rooted at a directory.
  public init(root: URL) {
    self.root = root
  }

  /// The directory for one app's report.
  public func directory(app: String, report: String) -> URL {
    root
      .appendingPathComponent(Self.sanitized(app), isDirectory: true)
      .appendingPathComponent(Self.sanitized(report), isDirectory: true)
  }

  /// Writes one segment's text.
  @discardableResult
  public func write(
    _ text: String,
    app: String,
    report: String,
    processingDate: String,
    segmentID: String
  ) throws -> URL {
    let folder = directory(app: app, report: report)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appendingPathComponent(
      "\(processingDate)-\(Self.sanitized(segmentID)).tsv"
    )
    try text.write(to: file, atomically: true, encoding: .utf8)
    return file
  }

  /// The report names saved for an app.
  public func reportNames(app: String) -> [String] {
    let folder = root.appendingPathComponent(Self.sanitized(app), isDirectory: true)
    let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
    return names.filter { !$0.hasPrefix(".") }.sorted()
  }

  /// Loads every saved file for a report, oldest processing date first.
  public func files(app: String, report: String) throws -> [ArchivedReportFile] {
    let folder = directory(app: app, report: report)
    guard FileManager.default.fileExists(atPath: folder.path) else {
      return []
    }
    return try FileManager.default.contentsOfDirectory(atPath: folder.path)
      .filter { $0.hasSuffix(".tsv") }
      .sorted()
      .map { name in
        let text = try String(
          contentsOf: folder.appendingPathComponent(name),
          encoding: .utf8
        )
        return ArchivedReportFile(
          processingDate: String(name.prefix(10)),
          table: ReportTable(text: text)
        )
      }
  }

  /// Loads a report's rows for data dates in `from...to` (`yyyy-MM-dd`).
  ///
  /// Apple can restate a day in a later processing date, so for each data
  /// date only the rows from the latest processing date are kept.
  public func rows(
    app: String,
    report: String,
    from start: String,
    to end: String
  ) throws -> ReportTable {
    try Self.deduplicated(files(app: app, report: report), from: start, to: end)
  }
}

extension ReportArchive {
  /// Keeps, for each data date in range, only the latest file's rows.
  public static func deduplicated(
    _ files: [ArchivedReportFile],
    from start: String,
    to end: String
  ) -> ReportTable {
    let latest = latestProcessingDates(files)
    var columns: [String] = []
    var rows: [[String: String]] = []
    for file in files {
      for column in file.table.columns where !columns.contains(column) {
        columns.append(column)
      }
      rows += file.table.rows.filter { row in
        let date = row[dateColumn] ?? file.processingDate
        return date >= start && date <= end && latest[date] == file.processingDate
      }
    }
    return ReportTable(columns: columns, rows: rows)
  }

  /// The latest processing date that contains each data date.
  private static func latestProcessingDates(_ files: [ArchivedReportFile]) -> [String: String] {
    var latest: [String: String] = [:]
    for file in files {
      for row in file.table.rows {
        let date = row[dateColumn] ?? file.processingDate
        latest[date] = max(latest[date] ?? "", file.processingDate)
      }
    }
    return latest
  }

  fileprivate static func sanitized(_ component: String) -> String {
    component.replacingOccurrences(of: "/", with: "-")
  }
}
