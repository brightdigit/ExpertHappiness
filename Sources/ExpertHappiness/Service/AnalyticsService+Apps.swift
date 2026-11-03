//
//  AnalyticsService+Apps.swift
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
  /// Lists the apps on the team.
  public func apps() async throws -> [AppSummary] {
    try await perform { client in
      let output = try await client.apps_getCollection(
        .init(query: .init(fields_lbrack_apps_rbrack_: [.name, .bundleId], limit: Self.pageLimit))
      )
      let body = try output.ok.body.json
      try requireSinglePage(next: body.links.next, operation: "apps")
      return body.data.map { app in
        AppSummary(
          id: app.id,
          name: app.attributes?.name ?? "",
          bundleID: app.attributes?.bundleId ?? ""
        )
      }
    }
  }

  /// Finds an app by App Store Connect ID or bundle ID.
  ///
  /// - Throws: ``AnalyticsError/appNotFound(_:)`` when nothing matches.
  public func app(matching identifier: String) async throws -> AppSummary {
    let all = try await apps()
    guard let match = all.first(where: { $0.id == identifier || $0.bundleID == identifier })
    else {
      throw AnalyticsError.appNotFound(identifier)
    }
    return match
  }
}
