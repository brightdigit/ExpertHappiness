//
//  AnalyticsService+Finance.swift
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
internal import Gzip
internal import OpenAPIRuntime

extension AnalyticsService {
  /// The largest finance report this downloads, compressed.
  private static let financeReportLimit = 64 * 1_024 * 1_024

  /// Downloads one month's finance report as tab-separated text.
  ///
  /// - Parameters:
  ///   - vendorNumber: The vendor number shown in Payments and Financial Reports.
  ///   - month: Apple's fiscal month as `yyyy-MM`.
  ///   - type: Which report to fetch.
  /// - Returns: The report text, or `nil` when Apple has no report for that
  ///   month (it answers 404, for example for a month with no sales).
  /// - Throws: ``AnalyticsError`` for any other HTTP error, or a decoding
  ///   error if the report isn't valid gzip.
  public func financeReport(
    vendorNumber: String,
    month: String,
    type: FinanceReportType = .financeDetail
  ) async throws -> String? {
    do {
      return try await perform { client in
        let output = try await client.financeReports_getCollection(
          .init(
            query: .init(
              filter_lbrack_vendorNumber_rbrack_: [vendorNumber],
              filter_lbrack_reportType_rbrack_: [
                .init(rawValue: type.rawValue) ?? .FINANCE_DETAIL
              ],
              filter_lbrack_regionCode_rbrack_: [type.allRegionsCode],
              filter_lbrack_reportDate_rbrack_: [month]
            )
          )
        )
        let body = try output.ok.body.application_a_hyphen_gzip
        let compressed = try await Data(collecting: body, upTo: Self.financeReportLimit)
        let data = compressed.isGzipped ? try compressed.gunzipped() : compressed
        return String(decoding: data, as: UTF8.self)
      }
    } catch AnalyticsError.http(status: 404, details: _) {
      return nil
    }
  }
}
