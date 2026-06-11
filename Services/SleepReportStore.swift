//
//  SleepReportStore.swift
//  ICS
//

import Foundation

@MainActor
final class SleepReportStore: ObservableObject {
    @Published private(set) var lastReport: StoredSleepReport?

    private let fileName = "last_sleep_report.json"

    init() {
        lastReport = loadLastReport()
    }

    func save(_ output: SleepAnalysisOutput, sourceFileName: String) {
        let report = StoredSleepReport(
            analyzedAt: Date(),
            sourceFileName: sourceFileName,
            result: output.result,
            stageTimeline: output.stageTimeline
        )
        lastReport = report
        persist(report)
    }

    private var reportURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    private func persist(_ report: StoredSleepReport) {
        do {
            let data = try JSONEncoder().encode(report)
            try data.write(to: reportURL, options: .atomic)
        } catch {
            print("Failed to save sleep report: \(error.localizedDescription)")
        }
    }

    private func loadLastReport() -> StoredSleepReport? {
        guard FileManager.default.fileExists(atPath: reportURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: reportURL)
            return try JSONDecoder().decode(StoredSleepReport.self, from: data)
        } catch {
            print("Failed to load sleep report: \(error.localizedDescription)")
            return nil
        }
    }
}
