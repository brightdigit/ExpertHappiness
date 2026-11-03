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
/// Specs are usually decoded from a JSON file (see ``SummaryConfiguration``).
/// Missing columns are reported rather than guessed, so a renamed column
/// shows up in the summary output.
public struct SummarySpec: Sendable, Equatable, Codable {
  private enum CodingKeys: String, CodingKey {
    case title
    case reportNameContains
    case reportNameExcludes
    case groupBy
    case values
    case latestDateOnly
  }

  /// A short title for the summary table.
  public let title: String
  /// Text the report name must contain (case-insensitive).
  public let reportNameContains: String
  /// Text the report name must not contain, e.g. "Detailed".
  public let reportNameExcludes: String?
  /// Columns to group rows by. Missing ones are skipped.
  public let groupBy: [String]
  /// Numeric columns to sum. Missing ones are skipped. Empty means every
  /// column whose values are all numbers.
  public let values: [String]
  /// When true, only the latest data date in range is totaled. Use this for
  /// point-in-time counts like subscription states.
  public let latestDateOnly: Bool

  /// Creates a spec.
  public init(
    title: String,
    reportNameContains: String,
    reportNameExcludes: String? = nil,
    groupBy: [String] = [],
    values: [String] = [],
    latestDateOnly: Bool = false
  ) {
    self.title = title
    self.reportNameContains = reportNameContains
    self.reportNameExcludes = reportNameExcludes
    self.groupBy = groupBy
    self.values = values
    self.latestDateOnly = latestDateOnly
  }

  /// Decodes a spec. Only `title` and `reportNameContains` are required.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      title: try container.decode(String.self, forKey: .title),
      reportNameContains: try container.decode(String.self, forKey: .reportNameContains),
      reportNameExcludes: try container.decodeIfPresent(String.self, forKey: .reportNameExcludes),
      groupBy: try container.decodeIfPresent([String].self, forKey: .groupBy) ?? [],
      values: try container.decodeIfPresent([String].self, forKey: .values) ?? [],
      latestDateOnly: try container.decodeIfPresent(Bool.self, forKey: .latestDateOnly) ?? false
    )
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
