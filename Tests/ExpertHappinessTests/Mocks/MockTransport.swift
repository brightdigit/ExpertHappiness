//
//  MockTransport.swift
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
internal import HTTPTypes
internal import OpenAPIRuntime

/// A transport that answers from canned JSON per operation and records requests.
internal struct MockTransport: ClientTransport, Sendable {
  internal let recorder: RequestRecorder

  internal init(responses: [String: MockResponse]) {
    self.recorder = RequestRecorder(responses: responses)
  }

  internal func send(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let data: Data? =
      if let body {
        try await Data(collecting: body, upTo: 1_024 * 1_024)
      } else {
        nil
      }
    let response = await recorder.record(operationID: operationID, request: request, body: data)
    var fields = HTTPFields()
    fields[.contentType] = "application/json"
    return (
      HTTPResponse(status: .init(code: response.status), headerFields: fields),
      HTTPBody(response.json)
    )
  }
}
