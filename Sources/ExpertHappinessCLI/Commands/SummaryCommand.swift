//
//  SummaryCommand.swift
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

/// Prints Markdown totals from downloaded files. Needs no credentials.
internal struct SummaryCommand: ExpertHappinessCommand {
  internal static let commandName = "summary"
  internal static let abstract = "Print Markdown totals from downloaded reports"
  internal static let helpText = """
    SUMMARY - Total downloaded reports for a date range

    USAGE:
      expert-happiness summary --app <bundle ID> [--from 2026-09-27] [--to 2026-11-02]
        [--output Reports]

    Works offline from the files `download` saved. Restated days count once,
    from the latest processing date. Unique counts are summed per day, so
    they overstate unique devices across a range.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  internal func execute() async throws {
    let app = try config.requireApp()
    let archive = ReportArchive(root: config.output)
    let names = archive.reportNames(app: app)
    if names.isEmpty {
      throw CLIError.invalid(
        "No downloaded reports for \(app) under \(config.output.path). "
          + "Use the bundle ID, and run `download` first."
      )
    }
    print("## \(app): \(config.range.start) to \(config.range.end)\n")
    print("_App Store Connect analytics exclude watchOS downloads and usage._\n")
    for spec in SummarySpec.standard {
      let matching = names.filter { spec.matches(reportName: $0) }
      if matching.isEmpty {
        print("### \(spec.title)\n\nNo downloaded report matches \"\(spec.reportNameContains)\".\n")
        continue
      }
      for name in matching {
        let table = try archive.rows(
          app: app,
          report: name,
          from: config.range.start,
          to: config.range.end
        )
        print(MetricSummary(spec: spec, reportName: name, table: table).markdown())
        print("")
      }
    }
  }
}
