//
//  SegmentDownloader.swift
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

internal import Crypto
public import Foundation
internal import Gzip

/// Downloads a report segment from its pre-signed URL, checks it and
/// decompresses it to text.
///
/// The URL is pre-signed, so no `Authorization` header is sent.
public struct SegmentDownloader: Sendable {
  /// Fetches the raw bytes at a URL.
  public typealias Fetch = @Sendable (URL) async throws -> Data

  private let fetch: Fetch

  /// Creates a downloader. The default fetch uses `URLSession.shared`.
  public init(fetch: Fetch? = nil) {
    self.fetch =
      fetch ?? { url in
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
          throw AnalyticsError.segmentDownload("HTTP \(http.statusCode)")
        }
        return data
      }
  }

  /// Downloads, verifies and decompresses a segment.
  ///
  /// - Throws: ``AnalyticsError/segmentDownload(_:)`` on a checksum mismatch
  ///   or a file that isn't valid gzip or UTF-8.
  public func text(of segment: ReportSegmentSummary) async throws -> String {
    let compressed = try await fetch(segment.url)
    if let checksum = segment.checksum, !checksum.isEmpty {
      let digest = Insecure.MD5.hash(data: compressed)
        .map { String(format: "%02x", $0) }
        .joined()
      guard digest.caseInsensitiveCompare(checksum) == .orderedSame else {
        throw AnalyticsError.segmentDownload("checksum mismatch for segment \(segment.id)")
      }
    }
    let data: Data
    if compressed.isGzipped {
      do {
        data = try compressed.gunzipped()
      } catch {
        throw AnalyticsError.segmentDownload("couldn't decompress segment \(segment.id)")
      }
    } else {
      data = compressed
    }
    guard let text = String(data: data, encoding: .utf8) else {
      throw AnalyticsError.segmentDownload("segment \(segment.id) isn't UTF-8 text")
    }
    return text
  }
}
