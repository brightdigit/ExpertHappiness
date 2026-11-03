//
//  ReportTests.swift
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

internal import Crypto
internal import Foundation
internal import Gzip
internal import Testing

@testable internal import ExpertHappiness

@Suite("Reports")
internal struct ReportTests {
  private static func fixture(_ name: String) throws -> ReportTable {
    let url = try #require(
      Bundle.module.url(forResource: name, withExtension: "tsv", subdirectory: "Fixtures")
    )
    return ReportTable(text: try String(contentsOf: url, encoding: .utf8))
  }

  private static func restatedFiles() throws -> [ArchivedReportFile] {
    try ["2026-10-03", "2026-10-05"].map { date in
      ArchivedReportFile(processingDate: date, table: try fixture("discovery-\(date)"))
    }
  }

  @Test("Parses tab-separated text with a header")
  internal func parsesTabs() {
    let table = ReportTable(text: "Date\tCounts\n2026-10-01\t5\n\n2026-10-02\t7\n")
    #expect(table.columns == ["Date", "Counts"])
    #expect(
      table.rows == [
        ["Date": "2026-10-01", "Counts": "5"], ["Date": "2026-10-02", "Counts": "7"],
      ])
  }

  @Test("Falls back to commas")
  internal func parsesCommas() {
    let table = ReportTable(text: "Date,Counts\r\n2026-10-01,5\r\n")
    #expect(table.rows == [["Date": "2026-10-01", "Counts": "5"]])
  }

  @Test("Restated days count once, from the latest processing date")
  internal func deduplicatesRestatements() throws {
    let files = try Self.restatedFiles()
    let table = ReportArchive.deduplicated(files, from: "2026-10-01", to: "2026-10-02")
    // Oct 1 from the 10-03 file (2 rows); Oct 2 only from the 10-05 file (2 rows).
    #expect(table.rows.count == 4)
    #expect(!table.rows.contains { $0["Date"] == "2026-10-02" && $0["Counts"] == "10" })

    let onlyFirst = ReportArchive.deduplicated(files, from: "2026-10-01", to: "2026-10-01")
    #expect(onlyFirst.rows.count == 2)
  }

  @Test("Summary totals by event and source")
  internal func summarizes() throws {
    let files = try Self.restatedFiles()
    let table = ReportArchive.deduplicated(files, from: "2026-10-01", to: "2026-10-02")
    let spec = SummarySpec(
      title: "Impressions and page views by source",
      reportNameContains: "Discovery and Engagement",
      reportNameExcludes: "Detailed",
      groupBy: ["Event", "Source Type"],
      values: ["Counts", "Unique Counts"]
    )
    #expect(spec.matches(reportName: "App Store Discovery and Engagement Standard"))
    #expect(!spec.matches(reportName: "App Store Discovery and Engagement Detailed"))

    let summary = MetricSummary(spec: spec, reportName: "Discovery", table: table)
    #expect(summary.valueColumns == ["Counts", "Unique Counts"])
    #expect(summary.missingColumns.isEmpty)
    #expect(
      summary.rows == [
        .init(group: ["Impression", "App Store Search"], totals: [52, 41]),
        .init(group: ["Page view", "App Referrer"], totals: [2, 2]),
        .init(group: ["Page view", "App Store Search"], totals: [4, 3]),
      ]
    )
    #expect(summary.markdown().contains("| Impression | App Store Search | 52 | 41 |"))
  }

  @Test("Missing columns are reported, not guessed")
  internal func reportsMissingColumns() {
    let spec = SummarySpec(
      title: "T",
      reportNameContains: "X",
      groupBy: ["Nope"],
      values: ["Counts"]
    )
    let summary = MetricSummary(
      spec: spec,
      reportName: "X",
      table: ReportTable(text: "Date\tCounts\n2026-10-01\t3\n")
    )
    #expect(summary.missingColumns == ["Nope"])
    #expect(summary.rows == [.init(group: [], totals: [3])])
  }

  @Test("Archive writes and reads back by app and report")
  internal func archiveRoundTrip() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let archive = ReportArchive(root: root)
    try archive.write(
      "Date\tCounts\n2026-10-01\t5\n",
      app: "com.example",
      report: "App Downloads Standard",
      processingDate: "2026-10-02",
      segmentID: "seg/1"
    )
    #expect(archive.reportNames(app: "com.example") == ["App Downloads Standard"])
    let rows = try archive.rows(
      app: "com.example",
      report: "App Downloads Standard",
      from: "2026-10-01",
      to: "2026-10-31"
    )
    #expect(rows.rows == [["Date": "2026-10-01", "Counts": "5"]])
  }

  @Test("Downloader gunzips and checks the MD5 checksum")
  internal func downloads() async throws {
    let compressed = try Data("Date\tCounts\n2026-10-01\t5\n".utf8).gzipped()
    let md5 = Insecure.MD5.hash(data: compressed).map { String(format: "%02x", $0) }.joined()
    let downloader = SegmentDownloader { _ in compressed }
    let url = try #require(URL(string: "https://example.com/seg.gz"))

    let good = ReportSegmentSummary(id: "s", url: url, checksum: md5, sizeInBytes: nil)
    #expect(try await downloader.text(of: good) == "Date\tCounts\n2026-10-01\t5\n")

    let bad = ReportSegmentSummary(id: "s", url: url, checksum: "deadbeef", sizeInBytes: nil)
    await #expect(throws: AnalyticsError.self) {
      try await downloader.text(of: bad)
    }
  }
}
