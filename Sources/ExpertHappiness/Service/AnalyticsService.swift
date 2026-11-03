//
//  AnalyticsService.swift
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
public import OpenAPIRuntime

#if canImport(OpenAPIURLSession)
  internal import OpenAPIURLSession
#endif

/// Reads App Store Connect analytics reports for the apps on one team.
///
/// Each call signs a short-lived JWT with the team API key, so the key needs
/// the Admin role to create report requests, and Admin, Sales and Reports,
/// or Finance to read them.
public struct AnalyticsService: Sendable {
  /// The largest page App Store Connect returns.
  internal static let pageLimit = 200

  internal let tokenProvider: TokenProvider
  internal let transport: any ClientTransport

  /// Creates a service that talks to App Store Connect over `URLSession`.
  public init(credentials: APIKeyCredentials) {
    self.init(credentials: credentials, transport: URLSessionTransport())
  }

  /// Creates a service over a custom transport.
  public init(
    credentials: APIKeyCredentials,
    transport: any ClientTransport,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.tokenProvider = TokenProvider(credentials: credentials, now: now)
    self.transport = transport
  }
}
