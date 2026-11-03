//
//  SummarySpec.swift
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

/// How to total one analytics report: which report, which columns to group
/// by and which numeric columns to sum.
///
/// Column names come from Apple's report documentation. Candidates are tried
/// in order, and a missing column is reported rather than guessed, so a
/// renamed column shows up in the summary output.
public struct SummarySpec: Sendable, Equatable {
  /// A short title for the summary table.
  public let title: String
  /// Text the report name must contain (case-insensitive).
  public let reportNameContains: String
  /// Text the report name must not contain, e.g. "Detailed".
  public let reportNameExcludes: String?
  /// Columns to group rows by. Missing ones are skipped.
  public let groupBy: [String]
  /// Numeric columns to sum. Missing ones are skipped.
  public let values: [String]
  /// When true, only the latest data date in range is totaled. Use this for
  /// point-in-time counts like subscription states.
  public let latestDateOnly: Bool

  /// Creates a spec.
  public init(
    title: String,
    reportNameContains: String,
    reportNameExcludes: String? = "Detailed",
    groupBy: [String],
    values: [String],
    latestDateOnly: Bool = false
  ) {
    self.title = title
    self.reportNameContains = reportNameContains
    self.reportNameExcludes = reportNameExcludes
    self.groupBy = groupBy
    self.values = values
    self.latestDateOnly = latestDateOnly
  }

  /// Whether a report name matches this spec.
  public func matches(reportName: String) -> Bool {
    let name = reportName.lowercased()
    guard name.contains(reportNameContains.lowercased()) else {
      return false
    }
    if let excluded = reportNameExcludes, name.contains(excluded.lowercased()) {
      return false
    }
    return true
  }
}

extension SummarySpec {
  /// The reports the SPARK numbers need: discovery, downloads, purchases and
  /// subscriptions.
  public static let standard: [SummarySpec] = [
    SummarySpec(
      title: "Impressions and page views by source",
      reportNameContains: "Discovery and Engagement",
      groupBy: ["Event", "Source Type"],
      values: ["Counts", "Unique Counts"]
    ),
    SummarySpec(
      title: "Downloads by type and source",
      reportNameContains: "App Downloads",
      groupBy: ["Download Type", "Source Type"],
      values: ["Counts"]
    ),
    SummarySpec(
      title: "Purchases and proceeds (estimated)",
      reportNameContains: "App Store Purchases",
      groupBy: ["Purchase Type"],
      values: ["Purchases", "Proceeds in USD", "Sales in USD"]
    ),
    SummarySpec(
      title: "Subscription states (latest day in range)",
      reportNameContains: "Subscription State",
      reportNameExcludes: nil,
      groupBy: ["State Metric"],
      values: ["Counts", "Count", "Subscriptions"],
      latestDateOnly: true
    ),
    SummarySpec(
      title: "Subscription events",
      reportNameContains: "Subscription Event",
      reportNameExcludes: nil,
      groupBy: ["Event Grouping", "Event Sub Type"],
      values: ["Counts", "Count", "Quantity"]
    ),
  ]
}
