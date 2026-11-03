//
//  ReportSegmentSummary.swift
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

/// One downloadable, gzipped piece of a report instance.
public struct ReportSegmentSummary: Sendable, Equatable {
  /// The segment ID.
  public let id: String
  /// The pre-signed download URL.
  public let url: URL
  /// The MD5 checksum Apple reports for the compressed file, if any.
  public let checksum: String?
  /// The compressed size in bytes, if reported.
  public let sizeInBytes: Int?

  /// Creates a summary.
  public init(id: String, url: URL, checksum: String?, sizeInBytes: Int?) {
    self.id = id
    self.url = url
    self.checksum = checksum
    self.sizeInBytes = sizeInBytes
  }
}
