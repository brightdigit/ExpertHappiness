//
//  TokenProvider.swift
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

/// Hands out a signed token, reusing it until it's close to expiring.
internal actor TokenProvider {
  /// Tokens are re-signed once fewer than this many seconds remain.
  internal static let refreshMargin: TimeInterval = 5 * 60

  private let credentials: APIKeyCredentials
  private let now: @Sendable () -> Date
  private var cached: JSONWebToken?

  internal init(
    credentials: APIKeyCredentials,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.credentials = credentials
    self.now = now
  }

  /// Returns the cached token, or signs a new one when it's within
  /// ``refreshMargin`` of expiring.
  internal func token() throws -> JSONWebToken {
    let current = now()
    if let cached, cached.expiresAt.timeIntervalSince(current) > Self.refreshMargin {
      return cached
    }
    let fresh = try JSONWebToken(credentials: credentials, issuedAt: current)
    cached = fresh
    return fresh
  }
}
