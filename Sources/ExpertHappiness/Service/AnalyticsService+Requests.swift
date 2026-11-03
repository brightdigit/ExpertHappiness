//
//  AnalyticsService+Requests.swift
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

internal import AppStoreConnectOpenAPI
internal import OpenAPIRuntime

extension AnalyticsService {
  /// Lists the report requests for an app.
  public func reportRequests(appID: String) async throws -> [ReportRequestSummary] {
    try await perform { client in
      let output = try await client.apps_analyticsReportRequests_getToManyRelated(
        .init(path: .init(id: appID), query: .init(limit: Self.pageLimit))
      )
      let body = try output.ok.body.json
      try requireSinglePage(next: body.links.next, operation: "reportRequests")
      return body.data.map(Self.summary(of:))
    }
  }

  /// Creates a report request, or returns the app's existing one of the same
  /// access type, so running it twice never makes a duplicate.
  ///
  /// - Returns: The request, and whether it was newly created.
  public func createReportRequest(
    appID: String,
    accessType: ReportAccessType
  ) async throws -> (request: ReportRequestSummary, created: Bool) {
    let existing = try await reportRequests(appID: appID)
    if let match = existing.first(where: {
      $0.accessType == accessType && !$0.stoppedDueToInactivity
    }) {
      return (match, false)
    }
    let request = try await perform { client in
      let body = Components.Schemas.AnalyticsReportRequestCreateRequest(
        data: .init(
          _type: .analyticsReportRequests,
          attributes: .init(accessType: accessType == .ongoing ? .ONGOING : .ONE_TIME_SNAPSHOT),
          relationships: .init(app: .init(data: .init(_type: .apps, id: appID)))
        )
      )
      let output = try await client.analyticsReportRequests_createInstance(
        .init(body: .json(body))
      )
      return Self.summary(of: try output.created.body.json.data)
    }
    return (request, true)
  }
}

extension AnalyticsService {
  fileprivate static func summary(
    of request: Components.Schemas.AnalyticsReportRequest
  ) -> ReportRequestSummary {
    ReportRequestSummary(
      id: request.id,
      accessType: request.attributes?.accessType.flatMap {
        ReportAccessType(rawValue: $0.rawValue)
      },
      stoppedDueToInactivity: request.attributes?.stoppedDueToInactivity ?? false
    )
  }
}
