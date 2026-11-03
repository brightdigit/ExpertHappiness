//
//  SummaryConfigurationTests.swift
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

@Suite("Summary configuration")
internal struct SummaryConfigurationTests {
  @Test("Decodes JSON with optional fields defaulted")
  internal func decodesWithDefaults() throws {
    let json = """
      {"summaries": [
        {"title": "Downloads", "reportNameContains": "App Downloads",
          "reportNameExcludes": "Detailed", "groupBy": ["Source Type"], "values": ["Counts"]},
        {"title": "States", "reportNameContains": "Subscription State", "latestDateOnly": true}
      ]}
      """
    let config = try JSONDecoder().decode(SummaryConfiguration.self, from: Data(json.utf8))
    #expect(config.summaries.count == 2)
    #expect(config.summaries[1].groupBy.isEmpty)
    #expect(config.summaries[1].values.isEmpty)
    #expect(config.summaries[1].latestDateOnly)
    #expect(config.includes(reportName: "App Downloads Standard"))
    #expect(!config.includes(reportName: "App Downloads Detailed"))
  }

  @Test("Without values, every numeric non-ID column is totaled")
  internal func totalsNumericColumns() {
    let table = ReportTable(
      text: "Date\tApp Apple ID\tTerritory\tCounts\tProceeds\n"
        + "2026-10-01\t123\tUS\t3\t1.5\n2026-10-02\t123\tSE\t2\t2.5\n"
    )
    let summary = MetricSummary(
      spec: .allNumericColumns(of: "Report"),
      reportName: "Report",
      table: table
    )
    #expect(summary.valueColumns == ["Counts", "Proceeds"])
    #expect(summary.rows == [.init(group: [], totals: [5, 4])])
  }
}
