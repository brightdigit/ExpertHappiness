//
//  RequestCommand.swift
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

/// Creates the app's report requests. Safe to run more than once.
internal struct RequestCommand: ExpertHappinessCommand {
  internal static let commandName = "request"
  internal static let abstract = "Create report requests for an app (needs an Admin key)"
  internal static let helpText = """
    REQUEST - Create report requests for an app

    USAGE:
      expert-happiness request --app <id or bundle ID> [--access ongoing|snapshot|both]

    ongoing   daily reports from today on
    snapshot  a one-time backfill of history (downloads from 2024, subscriptions from 2025)
    both      the default

    Existing requests are reused, so running this twice creates nothing new.
    The first reports appear 1–2 days after a request is created.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  internal func execute() async throws {
    let accessTypes: [ReportAccessType]
    switch config.access {
    case "ongoing": accessTypes = [.ongoing]
    case "snapshot": accessTypes = [.oneTimeSnapshot]
    case "both": accessTypes = [.ongoing, .oneTimeSnapshot]
    default: throw CLIError.invalid("--access must be ongoing, snapshot or both.")
    }
    let service = try config.makeService()
    let app = try await service.app(matching: config.requireApp())
    for accessType in accessTypes {
      let (request, created) = try await service.createReportRequest(
        appID: app.id,
        accessType: accessType
      )
      let verb = created ? "Created" : "Already exists:"
      print("\(verb) \(accessType.rawValue) request \(request.id) for \(app.name)")
    }
  }
}
