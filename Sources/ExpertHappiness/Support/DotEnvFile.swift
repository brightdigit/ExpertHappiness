//
//  DotEnvFile.swift
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

/// Parses a `.env` file into variables.
///
/// swift-configuration's own `.env` parser keeps surrounding quotes, which
/// breaks a quoted one-line PEM such as
/// `ASC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIG…\n-----END PRIVATE KEY-----"`.
/// This parser strips one matching pair of `"` or `'` and leaves everything
/// inside untouched, including literal `\n` escapes, which
/// ``PrivateKeyMaterial/loadPEM()`` turns into newlines later.
///
/// Supported: `KEY=value`, `export KEY=value`, `#` comment lines and blank
/// lines. Not supported: multi-line values and variable expansion.
public enum DotEnvFile {
  /// Parses `.env` text. Later duplicates win.
  public static func parse(_ text: String) -> [String: String] {
    var variables: [String: String] = [:]
    for rawLine in text.split(whereSeparator: \.isNewline) {
      var line = rawLine.trimmingCharacters(in: .whitespaces)
      guard !line.isEmpty, !line.hasPrefix("#") else {
        continue
      }
      if line.hasPrefix("export ") {
        line = String(line.dropFirst("export ".count)).trimmingCharacters(in: .whitespaces)
      }
      guard let equals = line.firstIndex(of: "=") else {
        continue
      }
      let key = line[..<equals].trimmingCharacters(in: .whitespaces)
      guard !key.isEmpty else {
        continue
      }
      let value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
      variables[key] = unquoted(value)
    }
    return variables
  }

  /// Loads and parses a `.env` file. A missing file yields no variables.
  public static func load(path: String) throws -> [String: String] {
    guard FileManager.default.fileExists(atPath: path) else {
      return [:]
    }
    return parse(try String(contentsOfFile: path, encoding: .utf8))
  }

  private static func unquoted(_ value: String) -> String {
    guard value.count >= 2, let first = value.first, first == "\"" || first == "'",
      value.last == first
    else {
      return value
    }
    return String(value.dropFirst().dropLast())
  }
}
