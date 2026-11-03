//
//  ConfigurationKeys.swift
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

internal import ConfigKeyKit

/// Every configuration key the CLI reads.
///
/// Bases are dash-case: swift-configuration joins key components verbatim, so
/// an underscore would produce an unusable flag and defeat secret redaction.
internal enum ConfigurationKeys {
  internal static let keyID = OptionalConfigKey<String>("asc.key-id")
  internal static let issuerID = OptionalConfigKey<String>("asc.issuer-id")
  internal static let privateKeyPath = OptionalConfigKey<String>(
    "asc.private-key-path",
    isSecret: true
  )
  internal static let privateKey = OptionalConfigKey<String>("asc.private-key", isSecret: true)

  internal static let app = OptionalConfigKey<String>(cli: "app", env: "ASC_APP")
  internal static let fromDate = OptionalConfigKey<String>(cli: "from")
  internal static let toDate = OptionalConfigKey<String>(cli: "to")
  internal static let output = ConfigKey<String>(
    cli: "output",
    env: "ASC_REPORTS_DIR",
    default: "Reports"
  )
  internal static let access = ConfigKey<String>(cli: "access", default: "both")
  internal static let report = OptionalConfigKey<String>(cli: "report")
  internal static let envFile = ConfigKey<String>(cli: "env-file", default: ".env")

  /// Flags whose values are redacted from logs.
  internal static let secretCommandLineFlags: Set<String> = [
    "--asc-private-key", "--asc-private-key-path",
  ]

  /// Environment and `.env` variables whose values are redacted from logs.
  internal static let secretEnvironmentVariables: Set<String> = [
    "ASC_PRIVATE_KEY", "ASC_PRIVATE_KEY_PATH",
  ]
}
