//
//  AnalyticsService+Reports.swift
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
internal import Foundation
internal import OpenAPIRuntime

extension AnalyticsService {
  /// Lists the reports under a request, optionally narrowed by category.
  ///
  /// Without a category, this queries each known ``ReportCategory`` in turn.
  /// Apple returns categories its published spec doesn't list yet (for
  /// example `AD_ATTRIBUTION_KIT_ANALYTICS`), which the generated decoder
  /// rejects, so the unfiltered list can't be decoded.
  public func reports(
    requestID: String,
    category: ReportCategory? = nil
  ) async throws -> [ReportSummary] {
    guard let category else {
      var all: [ReportSummary] = []
      for known in ReportCategory.allCases {
        all += try await reports(requestID: requestID, category: known)
      }
      return all
    }
    return try await perform { client in
      let categoryFilter =
        Operations.analyticsReportRequests_reports_getToManyRelated.Input.Query
        .filter_lbrack_category_rbrack_PayloadPayload(rawValue: category.rawValue)
      let output = try await client.analyticsReportRequests_reports_getToManyRelated(
        .init(
          path: .init(id: requestID),
          query: .init(
            filter_lbrack_category_rbrack_: categoryFilter.map { [$0] },
            limit: Self.pageLimit
          )
        )
      )
      let body = try output.ok.body.json
      try requireSinglePage(next: body.links.next, operation: "reports")
      return body.data.map { report in
        ReportSummary(
          id: report.id,
          name: report.attributes?.name ?? report.id,
          category: report.attributes?.category.flatMap { ReportCategory(rawValue: $0.rawValue) }
        )
      }
    }
  }

  /// Lists a report's instances, optionally for specific processing dates.
  ///
  /// Dates are sent in chunks of at most 200, so each response fits one page.
  public func instances(
    reportID: String,
    granularity: Granularity = .daily,
    processingDates: [String]? = nil
  ) async throws -> [ReportInstanceSummary] {
    guard let processingDates else {
      return try await instancePage(reportID: reportID, granularity: granularity, dates: nil)
    }
    var results: [ReportInstanceSummary] = []
    var start = processingDates.startIndex
    while start < processingDates.endIndex {
      let end = min(start + Self.pageLimit, processingDates.endIndex)
      results += try await instancePage(
        reportID: reportID,
        granularity: granularity,
        dates: Array(processingDates[start..<end])
      )
      start = end
    }
    return results
  }

  /// Lists the downloadable segments of a report instance.
  public func segments(instanceID: String) async throws -> [ReportSegmentSummary] {
    try await perform { client in
      let output = try await client.analyticsReportInstances_segments_getToManyRelated(
        .init(path: .init(id: instanceID), query: .init(limit: Self.pageLimit))
      )
      let body = try output.ok.body.json
      try requireSinglePage(next: body.links.next, operation: "segments")
      return body.data.compactMap { segment in
        guard let text = segment.attributes?.url, let url = URL(string: text) else {
          return nil
        }
        return ReportSegmentSummary(
          id: segment.id,
          url: url,
          checksum: segment.attributes?.checksum,
          sizeInBytes: segment.attributes?.sizeInBytes
        )
      }
    }
  }

  private func instancePage(
    reportID: String,
    granularity: Granularity,
    dates: [String]?
  ) async throws -> [ReportInstanceSummary] {
    try await perform { client in
      let granularityFilter = Operations.analyticsReports_instances_getToManyRelated.Input.Query
        .filter_lbrack_granularity_rbrack_PayloadPayload(rawValue: granularity.rawValue)
      let output = try await client.analyticsReports_instances_getToManyRelated(
        .init(
          path: .init(id: reportID),
          query: .init(
            filter_lbrack_granularity_rbrack_: granularityFilter.map { [$0] },
            filter_lbrack_processingDate_rbrack_: dates,
            limit: Self.pageLimit
          )
        )
      )
      let body = try output.ok.body.json
      try requireSinglePage(next: body.links.next, operation: "instances")
      return body.data.map { instance in
        ReportInstanceSummary(
          id: instance.id,
          granularity: instance.attributes?.granularity.flatMap {
            Granularity(rawValue: $0.rawValue)
          },
          processingDate: instance.attributes?.processingDate ?? ""
        )
      }
    }
  }
}
