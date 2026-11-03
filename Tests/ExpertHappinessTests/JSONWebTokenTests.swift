//
//  JSONWebTokenTests.swift
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
internal import Foundation
internal import Testing

@testable internal import ExpertHappiness

@Suite("JSON Web Token")
internal struct JSONWebTokenTests {
  @Test("Header and claims match what App Store Connect expects")
  internal func headerAndClaims() throws {
    let credentials = TestCredentials.make()
    let issued = Date(timeIntervalSince1970: 1_800_000_000)
    let token = try JSONWebToken(credentials: credentials, issuedAt: issued)
    let parts = token.compact.split(separator: ".").map(String.init)
    #expect(parts.count == 3)

    let header = try JSONDecoder().decode(
      JSONWebToken.Header.self,
      from: try #require(Data(base64URLEncoded: parts[0]))
    )
    #expect(header == JSONWebToken.Header(kid: "TESTKEY123"))

    let claims = try JSONDecoder().decode(
      JSONWebToken.Claims.self,
      from: try #require(Data(base64URLEncoded: parts[1]))
    )
    #expect(claims.iss == credentials.issuerID)
    #expect(claims.aud == "appstoreconnect-v1")
    #expect(claims.iat == 1_800_000_000)
    #expect(claims.exp == 1_800_000_000 + 20 * 60)
  }

  @Test("Signature is raw ES256 and verifies with the public key")
  internal func signatureVerifies() throws {
    let credentials = TestCredentials.make()
    let token = try JSONWebToken(credentials: credentials)
    let parts = token.compact.split(separator: ".").map(String.init)
    let signatureData = try #require(Data(base64URLEncoded: parts[2]))
    #expect(signatureData.count == 64)
    let signature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)
    let signed = Data((parts[0] + "." + parts[1]).utf8)
    #expect(credentials.privateKey.publicKey.isValidSignature(signature, for: signed))
  }

  @Test("Lifetime is capped at 20 minutes")
  internal func lifetimeCapped() throws {
    let issued = Date(timeIntervalSince1970: 1_800_000_000)
    let token = try JSONWebToken(
      credentials: TestCredentials.make(),
      issuedAt: issued,
      lifetime: 3_600
    )
    #expect(token.expiresAt == issued.addingTimeInterval(20 * 60))
  }

  @Test("Inline PEM with literal \\n escapes loads")
  internal func inlinePEM() throws {
    let key = P256.Signing.PrivateKey()
    let escaped = key.pemRepresentation.replacingOccurrences(of: "\n", with: "\\n")
    let credentials = try APIKeyCredentials(
      keyID: "TESTKEY123",
      issuerID: "issuer",
      keyMaterial: .raw(escaped)
    )
    #expect(credentials.privateKey.rawRepresentation == key.rawRepresentation)
  }

  @Test("A bad key throws invalidPrivateKey")
  internal func badKey() {
    #expect(throws: AnalyticsError.self) {
      try APIKeyCredentials(keyID: "K", issuerID: "I", keyMaterial: .raw("not a key"))
    }
  }
}
