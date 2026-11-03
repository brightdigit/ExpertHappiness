//
//  AnalyticsService+ClientDispatch.swift
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
  /// Builds a generated client with the auth, error and logging middleware.
  internal func makeClient() throws -> Client {
    Client(
      serverURL: try Servers.Server1.url(),
      transport: transport,
      middlewares: [
        LoggingMiddleware(),
        ErrorResponseMiddleware(),
        AuthenticationMiddleware(tokenProvider: tokenProvider),
      ]
    )
  }

  /// Runs a client call, turning runtime wrappers back into ``AnalyticsError``.
  internal func perform<T>(_ call: (Client) async throws -> T) async throws -> T {
    do {
      return try await call(makeClient())
    } catch let error as AnalyticsError {
      throw error
    } catch let error as ClientError {
      if let underlying = error.underlyingError as? AnalyticsError {
        throw underlying
      }
      throw AnalyticsError.underlying(String(describing: error.underlyingError))
    } catch {
      throw AnalyticsError.underlying(String(describing: error))
    }
  }

  /// Throws ``AnalyticsError/truncated(operation:)`` when a response has more pages.
  internal func requireSinglePage(next: String?, operation: String) throws {
    if next != nil {
      throw AnalyticsError.truncated(operation: operation)
    }
  }
}
