//
//  CommandRunner.swift
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
internal import Foundation

/// Registers the commands, parses arguments and dispatches.
internal enum CommandRunner {
  internal static func run() async throws {
    let registry = CommandRegistry.shared
    await registry.register(AppsCommand.self)
    await registry.register(RequestCommand.self)
    await registry.register(StatusCommand.self)
    await registry.register(DownloadCommand.self)
    await registry.register(SummaryCommand.self)
    await registry.register(FinanceCommand.self)

    let parser = CommandLineParser()
    guard let name = parser.parseCommandName(), name != "help" else {
      await printGeneralHelp(registry: registry)
      return
    }
    if parser.isHelpRequested(), let metadata = await registry.metadata(for: name) {
      print(metadata.helpText)
      return
    }
    let command = try await registry.createCommand(named: name)
    try await command.execute()
  }

  private static func printGeneralHelp(registry: CommandRegistry) async {
    print(
      """
      expert-happiness — App Store Connect Analytics Reports

      USAGE:
        expert-happiness <command> [options]

      COMMANDS:
      """
    )
    for name in await registry.availableCommands {
      if let metadata = await registry.metadata(for: name) {
        print("  \(name.padding(toLength: 10, withPad: " ", startingAt: 0)) \(metadata.abstract)")
      }
    }
    print(
      """

      CREDENTIALS: put them in ./.env (see .env.example) or the environment.
      Flags work too, but show up in shell history and ps. Precedence: flags,
      then the environment, then .env (--env-file <path> to use another file).
        ASC_KEY_ID              --asc-key-id
        ASC_ISSUER_ID           --asc-issuer-id
        ASC_PRIVATE_KEY         --asc-private-key        inline PEM; literal \\n allowed (preferred)
        ASC_PRIVATE_KEY_PATH    --asc-private-key-path   path to the .p8 (fallback)
      If both private-key options are set, ASC_PRIVATE_KEY wins.

      Run `expert-happiness <command> --help` for a command's options.
      """
    )
  }
}
