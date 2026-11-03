//
//  AppsCommand.swift
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

internal import ExpertHappiness

/// Lists the team's apps. The first check that the API key works.
internal struct AppsCommand: ExpertHappinessCommand {
  internal static let commandName = "apps"
  internal static let abstract = "List the team's apps (checks the API key)"
  internal static let helpText = """
    APPS - List the team's apps

    USAGE:
      expert-happiness apps

    Prints each app's App Store Connect ID, bundle ID and name. Use either ID
    as --app in the other commands.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  internal func execute() async throws {
    let apps = try await config.makeService().apps()
    for app in apps {
      print("\(app.id)\t\(app.bundleID)\t\(app.name)")
    }
  }
}
