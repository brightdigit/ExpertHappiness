//
//  ReportTable.swift
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

/// A delimited report file parsed into rows keyed by column name.
///
/// Apple's analytics reports are tab-separated with a header row. A header
/// without tabs falls back to commas. Quoted fields aren't supported.
public struct ReportTable: Sendable, Equatable {
  /// The column names from the header row.
  public let columns: [String]
  /// One dictionary per data row.
  public let rows: [[String: String]]

  /// Parses report text.
  public init(text: String) {
    let lines =
      text
      .split(whereSeparator: \.isNewline)
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    guard let header = lines.first else {
      self.columns = []
      self.rows = []
      return
    }
    let separator: Character = header.contains("\t") ? "\t" : ","
    let columns = Self.fields(of: header, separator: separator)
    self.columns = columns
    self.rows = lines.dropFirst().map { line in
      let values = Self.fields(of: line, separator: separator)
      var row: [String: String] = [:]
      for (index, column) in columns.enumerated() where index < values.count {
        row[column] = values[index]
      }
      return row
    }
  }

  /// Creates a table from already-parsed rows.
  public init(columns: [String], rows: [[String: String]]) {
    self.columns = columns
    self.rows = rows
  }

  private static func fields(of line: String, separator: Character) -> [String] {
    line.split(separator: separator, omittingEmptySubsequences: false).map {
      $0.trimmingCharacters(in: .whitespaces)
        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
  }
}
