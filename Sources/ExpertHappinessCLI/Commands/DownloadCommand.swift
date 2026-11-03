//
//  DownloadCommand.swift
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
internal import Foundation

/// Downloads report segments for a date range into the archive.
internal struct DownloadCommand: ExpertHappinessCommand {
  internal static let commandName = "download"
  internal static let abstract = "Download daily report files for a date range"
  internal static let helpText = """
    DOWNLOAD - Download daily report files

    USAGE:
      expert-happiness download --app <id or bundle ID> [--from 2026-09-27] [--to 2026-11-02]
        [--output Reports] [--report <name contains>]

    Saves Reports/<bundle ID>/<report>/<processing date>-<segment>.tsv. Fetches
    processing dates through --to plus 5 days, because Apple can restate a
    day later. Files already on disk are skipped.
    """

  private let config: CLIConfiguration

  internal init(config: CLIConfiguration) {
    self.config = config
  }

  internal func execute() async throws {
    let service = try config.makeService()
    let app = try await service.app(matching: config.requireApp())
    let archive = ReportArchive(root: config.output)
    let downloader = SegmentDownloader()
    let dates = config.range.processingDates()
    var saved = 0
    var skipped = 0
    for request in try await service.reportRequests(appID: app.id) {
      let reports = try await service.reports(requestID: request.id)
      for report in reports where ReportSelection.includes(report, filter: config.report) {
        let instances = try await service.instances(reportID: report.id, processingDates: dates)
        for instance in instances {
          for segment in try await service.segments(instanceID: instance.id) {
            let folder = archive.directory(app: app.bundleID, report: report.name)
            let name = "\(instance.processingDate)-\(segment.id).tsv"
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent(name).path) {
              skipped += 1
              continue
            }
            let text = try await downloader.text(of: segment)
            try archive.write(
              text,
              app: app.bundleID,
              report: report.name,
              processingDate: instance.processingDate,
              segmentID: segment.id
            )
            saved += 1
          }
        }
        print("\(report.name): \(instances.count) instances")
      }
    }
    print("Saved \(saved) files, skipped \(skipped) already on disk, under \(config.output.path)")
  }
}
