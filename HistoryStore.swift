import Foundation

final class HistoryStore {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("MicTimer", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("calls.json")
    }

    func load() -> [CallRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? JSONDecoder().decode([CallRecord].self, from: data) else { return [] }
        return records.sorted { $0.start > $1.start }
    }

    func save(_ records: [CallRecord]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(records).write(to: fileURL, options: .atomic)
    }
}
