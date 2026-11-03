//
//  SummaryConfiguration.swift
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

public import Foundation

/// A set of ``SummarySpec``s loaded from JSON, so each project decides which
/// reports to download and how to total them.
///
/// ```json
/// {
///   "summaries": [
///     {
///       "title": "Downloads by type and source",
///       "reportNameContains": "App Downloads",
///       "reportNameExcludes": "Detailed",
///       "groupBy": ["Download Type", "Source Type"],
///       "values": ["Counts"]
///     }
///   ]
/// }
/// ```
public struct SummaryConfiguration: Sendable, Equatable, Codable {
  /// The summaries, in output order.
  public let summaries: [SummarySpec]

  /// Creates a configuration.
  public init(summaries: [SummarySpec]) {
    self.summaries = summaries
  }

  /// Loads a configuration from a JSON file.
  ///
  /// - Throws: An error if the file can't be read or decoded.
  public static func load(from url: URL) throws -> SummaryConfiguration {
    try JSONDecoder().decode(SummaryConfiguration.self, from: Data(contentsOf: url))
  }

  /// Whether any summary uses a report with this name.
  public func includes(reportName: String) -> Bool {
    summaries.contains { $0.matches(reportName: reportName) }
  }
}
