//
//  CLIConfiguration.swift
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
internal import Configuration
internal import ExpertHappiness
internal import Foundation

/// Everything a command can be configured with. Commands read only what they
/// need; credentials are resolved lazily so `--help` works without them.
internal struct CLIConfiguration: ConfigurationParseable {
  internal typealias ConfigReader = Configuration.ConfigReader
  internal typealias BaseConfig = Never

  internal let keyID: String?
  internal let issuerID: String?
  internal let privateKeyPath: String?
  internal let privateKey: String?
  internal let app: String?
  internal let range: DateRange
  internal let output: URL
  internal let access: String
  internal let report: String?
  internal let vendorNumber: String?
  internal let summaries: SummaryConfiguration?
  internal let fromMonth: String?
  internal let toMonth: String?

  internal init(configuration: ConfigReader, base: Never?) async throws {
    keyID = configuration.read(ConfigurationKeys.keyID)
    issuerID = configuration.read(ConfigurationKeys.issuerID)
    privateKeyPath = configuration.read(ConfigurationKeys.privateKeyPath)
    privateKey = configuration.read(ConfigurationKeys.privateKey)
    app = configuration.read(ConfigurationKeys.app)
    range = try DateRange(
      from: configuration.read(ConfigurationKeys.fromDate),
      to: configuration.read(ConfigurationKeys.toDate)
    )
    output = URL(fileURLWithPath: configuration.read(ConfigurationKeys.output))
    access = configuration.read(ConfigurationKeys.access)
    report = configuration.read(ConfigurationKeys.report)
    vendorNumber = configuration.read(ConfigurationKeys.vendorNumber)
    summaries = try configuration.read(ConfigurationKeys.summaryConfig).map { path in
      try SummaryConfiguration.load(
        from: URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
      )
    }
    fromMonth = configuration.read(ConfigurationKeys.fromMonth)
    toMonth = configuration.read(ConfigurationKeys.toMonth)
  }

  /// Reads the configuration from, in order of precedence: command-line
  /// flags, the process environment, then the `.env` file (`./.env`, or
  /// `--env-file <path>`). A missing `.env` file isn't an error.
  internal static func load() async throws -> CLIConfiguration {
    let commandLine = CommandLineArgumentsProvider(
      secretsSpecifier: .specific(ConfigurationKeys.secretCommandLineFlags)
    )
    let envFilePath = Configuration.ConfigReader(provider: commandLine)
      .read(ConfigurationKeys.envFile)
    let fileVariables = try DotEnvFile.load(
      path: (envFilePath as NSString).expandingTildeInPath
    )
    let reader = Configuration.ConfigReader(providers: [
      commandLine,
      EnvironmentVariablesProvider(
        secretsSpecifier: .specific(ConfigurationKeys.secretEnvironmentVariables)
      ),
      EnvironmentVariablesProvider(
        environmentVariables: fileVariables,
        secretsSpecifier: .specific(ConfigurationKeys.secretEnvironmentVariables)
      ),
    ])
    return try await CLIConfiguration(configuration: reader)
  }

  /// Builds the service, or explains which credential is missing.
  internal func makeService() throws -> AnalyticsService {
    guard let keyID, !keyID.isEmpty else {
      throw CLIError.missing("ASC_KEY_ID (or --asc-key-id)")
    }
    guard let issuerID, !issuerID.isEmpty else {
      throw CLIError.missing("ASC_ISSUER_ID (or --asc-issuer-id)")
    }
    let material: PrivateKeyMaterial
    if let privateKey, !privateKey.isEmpty {
      material = .raw(privateKey)
    } else if let privateKeyPath, !privateKeyPath.isEmpty {
      material = .file(path: (privateKeyPath as NSString).expandingTildeInPath)
    } else {
      throw CLIError.missing(
        "ASC_PRIVATE_KEY (inline PEM), or ASC_PRIVATE_KEY_PATH as a fallback"
      )
    }
    let credentials = try APIKeyCredentials(
      keyID: keyID,
      issuerID: issuerID,
      keyMaterial: material
    )
    return AnalyticsService(credentials: credentials)
  }

  /// The `--app` value, or an error naming the flag.
  internal func requireApp() throws -> String {
    guard let app, !app.isEmpty else {
      throw CLIError.missing("--app (an app ID or bundle ID; see `expert-happiness apps`)")
    }
    return app
  }
}
