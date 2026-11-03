//
//  JSONWebToken.swift
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

/// An ES256-signed JSON Web Token for the App Store Connect API.
///
/// App Store Connect rejects tokens that live longer than 20 minutes, so
/// ``init(credentials:issuedAt:lifetime:)`` caps the lifetime there.
public struct JSONWebToken: Sendable {
  /// The audience App Store Connect expects in every token.
  public static let audience = "appstoreconnect-v1"
  /// The longest lifetime App Store Connect accepts.
  public static let maximumLifetime: TimeInterval = 20 * 60

  /// The compact serialization: `header.claims.signature`, each base64url.
  public let compact: String
  /// When the token stops being valid.
  public let expiresAt: Date

  /// Signs a new token.
  ///
  /// - Parameters:
  ///   - credentials: The API key to sign with.
  ///   - issuedAt: The `iat` claim. Defaults to now.
  ///   - lifetime: Seconds until `exp`, capped at ``maximumLifetime``.
  /// - Throws: An error if encoding or signing fails.
  public init(
    credentials: APIKeyCredentials,
    issuedAt: Date = Date(),
    lifetime: TimeInterval = JSONWebToken.maximumLifetime
  ) throws {
    let issued = Int(issuedAt.timeIntervalSince1970)
    let expires = issued + Int(min(lifetime, Self.maximumLifetime))
    let header = Header(kid: credentials.keyID)
    let claims = Claims(
      iss: credentials.issuerID,
      iat: issued,
      exp: expires,
      aud: Self.audience
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let signingInput =
      try encoder.encode(header).base64URLEncodedString() + "."
      + encoder.encode(claims).base64URLEncodedString()
    // JWT's ES256 wants the raw 64-byte r‖s signature, not DER.
    let signature = try credentials.privateKey.signature(for: Data(signingInput.utf8))
    self.compact = signingInput + "." + signature.rawRepresentation.base64URLEncodedString()
    self.expiresAt = Date(timeIntervalSince1970: TimeInterval(expires))
  }
}

extension JSONWebToken {
  internal struct Header: Codable, Equatable {
    internal var alg = "ES256"
    // periphery:ignore - encoded by JSONEncoder, never read in Swift.
    internal var kid: String
    internal var typ = "JWT"
  }

  internal struct Claims: Codable, Equatable {
    internal var iss: String
    internal var iat: Int
    internal var exp: Int
    internal var aud: String
  }
}
