//
//  TokenProviderTests.swift
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
internal import Synchronization
internal import Testing

@testable internal import ExpertHappiness

@Suite("Token caching")
internal struct TokenProviderTests {
  private final class Clock: Sendable {
    private let value: Mutex<Date>

    var now: Date {
      value.withLock { $0 }
    }

    init(_ date: Date) {
      value = Mutex(date)
    }

    func advance(by seconds: TimeInterval) {
      value.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
  }

  @Test("Reuses the token until it nears expiry, then re-signs")
  internal func cachesThenRefreshes() async throws {
    let clock = Clock(Date(timeIntervalSince1970: 1_800_000_000))
    let provider = TokenProvider(credentials: TestCredentials.make()) { clock.now }
    let first = try await provider.token()

    clock.advance(by: 10 * 60)
    let second = try await provider.token()
    #expect(second.compact == first.compact)

    clock.advance(by: 6 * 60)
    let third = try await provider.token()
    #expect(third.compact != first.compact)
  }
}
