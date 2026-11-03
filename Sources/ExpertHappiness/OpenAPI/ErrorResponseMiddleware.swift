//
//  ErrorResponseMiddleware.swift
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
internal import HTTPTypes
internal import OpenAPIRuntime

/// Turns any 4xx/5xx response into ``AnalyticsError/http(status:details:)``
/// before the generated client decodes it, so callers can use the generated
/// `ok` / `created` accessors without switching over every error case.
internal struct ErrorResponseMiddleware: ClientMiddleware {
  private static let bodyLimit = 256 * 1_024

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let (response, responseBody) = try await next(request, body, baseURL)
    guard response.status.code >= 400 else {
      return (response, responseBody)
    }
    var details: [String] = []
    if let responseBody,
      let data = try? await Data(collecting: responseBody, upTo: Self.bodyLimit),
      let decoded = try? JSONDecoder().decode(Components.Schemas.ErrorResponse.self, from: data)
    {
      details = (decoded.errors ?? []).map { error in
        [error.title, error.detail].filter { !$0.isEmpty }.joined(separator: " — ")
      }
    }
    throw AnalyticsError.http(status: response.status.code, details: details)
  }
}
