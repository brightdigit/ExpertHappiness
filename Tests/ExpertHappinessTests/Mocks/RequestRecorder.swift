//
//  RequestRecorder.swift
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

/// Records requests sent through ``MockTransport`` and serves its responses.
internal actor RequestRecorder {
  /// One recorded request.
  internal struct Entry: Sendable {
    internal let operationID: String
    internal let request: HTTPRequest
    internal let body: Data?
  }

  private let responses: [String: MockResponse]
  internal private(set) var entries: [Entry] = []

  internal var operationIDs: [String] {
    entries.map(\.operationID)
  }

  internal init(responses: [String: MockResponse]) {
    self.responses = responses
  }

  internal func record(operationID: String, request: HTTPRequest, body: Data?) -> MockResponse {
    entries.append(Entry(operationID: operationID, request: request, body: body))
    return responses[operationID]
      ?? MockResponse(
        status: 404,
        json:
          #"{"errors":[{"status":"404","code":"NOT_FOUND","title":"No mock","detail":"\#(operationID)"}]}"#
      )
  }
}
