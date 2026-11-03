//
//  AnalyticsError.swift
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

/// Errors thrown by ``AnalyticsService`` and the report helpers.
public enum AnalyticsError: LocalizedError, Sendable, Equatable {
  /// The private key couldn't be read or parsed.
  case invalidPrivateKey(String)
  /// App Store Connect returned an error status. `details` holds each error's
  /// title and detail from the response body.
  case http(status: Int, details: [String])
  /// A list call returned more results than one page holds.
  case truncated(operation: String)
  /// No app matched an app ID or bundle ID.
  case appNotFound(String)
  /// A segment download failed or its checksum didn't match.
  case segmentDownload(String)
  /// Any other failure, described.
  case underlying(String)

  /// A human-readable description.
  public var errorDescription: String? {
    switch self {
    case .invalidPrivateKey(let reason):
      return "Couldn't load the App Store Connect private key: \(reason)"
    case .http(let status, let details):
      let joined = details.isEmpty ? "" : ": " + details.joined(separator: "; ")
      return "App Store Connect returned HTTP \(status)\(joined)"
    case .truncated(let operation):
      return "\(operation) returned more than one page; narrow the request."
    case .appNotFound(let app):
      return "No app matches \(app). Run `expert-happiness apps` to list them."
    case .segmentDownload(let reason):
      return "Couldn't download a report segment: \(reason)"
    case .underlying(let reason):
      return reason
    }
  }
}
