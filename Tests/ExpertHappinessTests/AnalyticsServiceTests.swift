//
//  AnalyticsServiceTests.swift
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
internal import HTTPTypes
internal import Testing

@testable internal import ExpertHappiness

@Suite("Analytics service")
internal struct AnalyticsServiceTests {
  private static let appsJSON = """
    {"data":[{"type":"apps","id":"6700000001",
      "attributes":{"name":"AtLeast","bundleId":"com.brightdigit.AtLeast"}}],
    "links":{"self":"https://api.appstoreconnect.apple.com/v1/apps"}}
    """

  private func service(_ responses: [String: MockResponse]) -> (AnalyticsService, MockTransport) {
    let transport = MockTransport(responses: responses)
    return (AnalyticsService(credentials: TestCredentials.make(), transport: transport), transport)
  }

  @Test("Lists apps and sends a bearer token")
  internal func listsApps() async throws {
    let (service, transport) = service(["apps_getCollection": MockResponse(json: Self.appsJSON)])
    let apps = try await service.apps()
    #expect(
      apps == [AppSummary(id: "6700000001", name: "AtLeast", bundleID: "com.brightdigit.AtLeast")]
    )
    let entry = try #require(await transport.recorder.entries.first)
    let authorization = try #require(entry.request.headerFields[.authorization])
    #expect(authorization.hasPrefix("Bearer "))
    #expect(authorization.split(separator: ".").count == 3)
  }

  @Test("Finds an app by bundle ID")
  internal func findsByBundleID() async throws {
    let (service, _) = service(["apps_getCollection": MockResponse(json: Self.appsJSON)])
    let app = try await service.app(matching: "com.brightdigit.AtLeast")
    #expect(app.id == "6700000001")
    await #expect(throws: AnalyticsError.appNotFound("nope")) {
      try await service.app(matching: "nope")
    }
  }

  @Test("A next link throws truncated instead of dropping results")
  internal func truncation() async throws {
    let json = """
      {"data":[],"links":{"self":"https://x/v1/apps","next":"https://x/v1/apps?cursor=abc"}}
      """
    let (service, _) = service(["apps_getCollection": MockResponse(json: json)])
    await #expect(throws: AnalyticsError.truncated(operation: "apps")) {
      try await service.apps()
    }
  }

  @Test("Error responses surface status and details")
  internal func httpError() async throws {
    let json = """
      {"errors":[{"status":"403","code":"FORBIDDEN_ERROR","title":"Forbidden","detail":"Needs Admin"}]}
      """
    let (service, _) = service(["apps_getCollection": MockResponse(status: 403, json: json)])
    await #expect(throws: AnalyticsError.http(status: 403, details: ["Forbidden — Needs Admin"])) {
      try await service.apps()
    }
  }

  @Test("createReportRequest reuses an existing request")
  internal func reusesExistingRequest() async throws {
    let existing = """
      {"data":[{"type":"analyticsReportRequests","id":"req-1",
        "attributes":{"accessType":"ONGOING","stoppedDueToInactivity":false}}],
      "links":{"self":"https://x"}}
      """
    let (service, transport) = service([
      "apps_analyticsReportRequests_getToManyRelated": MockResponse(json: existing)
    ])
    let (request, created) = try await service.createReportRequest(
      appID: "6700000001",
      accessType: .ongoing
    )
    #expect(request.id == "req-1")
    #expect(!created)
    #expect(
      await transport.recorder.operationIDs == ["apps_analyticsReportRequests_getToManyRelated"]
    )
  }

  @Test("createReportRequest posts when none exists")
  internal func createsRequest() async throws {
    let none = #"{"data":[],"links":{"self":"https://x"}}"#
    let createdJSON = """
      {"data":{"type":"analyticsReportRequests","id":"req-2",
        "attributes":{"accessType":"ONE_TIME_SNAPSHOT","stoppedDueToInactivity":false}},
      "links":{"self":"https://x"}}
      """
    let (service, transport) = service([
      "apps_analyticsReportRequests_getToManyRelated": MockResponse(json: none),
      "analyticsReportRequests_createInstance": MockResponse(status: 201, json: createdJSON),
    ])
    let (request, created) = try await service.createReportRequest(
      appID: "6700000001",
      accessType: .oneTimeSnapshot
    )
    #expect(created)
    let expected = ReportRequestSummary(
      id: "req-2",
      accessType: .oneTimeSnapshot,
      stoppedDueToInactivity: false
    )
    #expect(request == expected)
    let post = try #require(await transport.recorder.entries.last)
    let body = try #require(post.body.flatMap { String(data: $0, encoding: .utf8) })
    #expect(body.contains("ONE_TIME_SNAPSHOT"))
    #expect(body.contains("6700000001"))
  }

  @Test("Instances are requested with the processing-date filter")
  internal func instancesFilter() async throws {
    let json = """
      {"data":[{"type":"analyticsReportInstances","id":"inst-1",
        "attributes":{"granularity":"DAILY","processingDate":"2026-10-01"}}],
      "links":{"self":"https://x"}}
      """
    let (service, transport) = service([
      "analyticsReports_instances_getToManyRelated": MockResponse(json: json)
    ])
    let instances = try await service.instances(
      reportID: "r-1",
      processingDates: ["2026-10-01", "2026-10-02"]
    )
    #expect(
      instances == [
        ReportInstanceSummary(id: "inst-1", granularity: .daily, processingDate: "2026-10-01")
      ])
    let path = try #require(await transport.recorder.entries.first?.request.path)
    #expect(path.contains("processingDate"))
    #expect(path.contains("2026-10-02"))
  }
}
