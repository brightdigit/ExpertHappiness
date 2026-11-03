//
//  StatusCommand.swift
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

/// Shows an app's requests and the reports the summary uses.
internal struct StatusCommand: ExpertHappinessCommand {
  internal static let commandName = "status"
  internal static let abstract = "Show an app's report requests and available reports"
  internal static let helpText = """
    STATUS - Show report requests and reports for an app

    USAGE:
      expert-happiness status --app <id or bundle ID> [--report <name contains>] [--summary-config <file>]

    Lists each request and its reports. With --report or --summary-config,
    shows only the selected reports, with their daily instance count and
    latest processing date. Without either, lists every report name.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  internal func execute() async throws {
    let service = try config.makeService()
    let app = try await service.app(matching: config.requireApp())
    let requests = try await service.reportRequests(appID: app.id)
    if requests.isEmpty {
      print("No report requests for \(app.name). Run `expert-happiness request --app \(app.id)`.")
      return
    }
    for request in requests {
      let stopped = request.stoppedDueToInactivity ? " (stopped: inactive)" : ""
      print("\(request.accessType?.rawValue ?? "?") request \(request.id)\(stopped)")
      let reports = try await service.reports(requestID: request.id)
      print("  \(reports.count) reports available")
      for report in reports {
        guard let selected = ReportSelection.includes(report, config: config) else {
          print("  - \(report.name)")
          continue
        }
        guard selected else {
          continue
        }
        let line: String
        do {
          let instances = try await service.instances(reportID: report.id)
          let latest = instances.map(\.processingDate).max() ?? "none yet"
          line = "\(instances.count) daily instances, latest \(latest)"
        } catch AnalyticsError.truncated {
          line = "more than 200 daily instances"
        }
        print("  - \(report.name): \(line)")
      }
    }
  }
}
