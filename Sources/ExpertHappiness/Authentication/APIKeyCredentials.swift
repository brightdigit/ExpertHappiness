//
//  APIKeyCredentials.swift
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

public import Crypto

/// An App Store Connect team API key: the key ID, the issuer ID and the
/// private key that signs each request's JSON Web Token.
public struct APIKeyCredentials: Sendable {
  /// The key ID shown next to the key in App Store Connect.
  public let keyID: String
  /// The issuer ID shown above the team keys list in App Store Connect.
  public let issuerID: String
  /// The P-256 private key from the `.p8` file.
  public let privateKey: P256.Signing.PrivateKey

  /// Creates credentials from an already-parsed private key.
  public init(keyID: String, issuerID: String, privateKey: P256.Signing.PrivateKey) {
    self.keyID = keyID
    self.issuerID = issuerID
    self.privateKey = privateKey
  }

  /// Creates credentials by loading and parsing PEM key material.
  ///
  /// - Throws: ``AnalyticsError/invalidPrivateKey(_:)`` when the key can't be
  ///   read or isn't a P-256 key.
  public init(keyID: String, issuerID: String, keyMaterial: PrivateKeyMaterial) throws {
    let pem: String
    do {
      pem = try keyMaterial.loadPEM()
    } catch {
      throw AnalyticsError.invalidPrivateKey(String(describing: error))
    }
    do {
      let privateKey = try P256.Signing.PrivateKey(pemRepresentation: pem)
      self.init(keyID: keyID, issuerID: issuerID, privateKey: privateKey)
    } catch {
      throw AnalyticsError.invalidPrivateKey(String(describing: error))
    }
  }
}
