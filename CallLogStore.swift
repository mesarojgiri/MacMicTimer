import Foundation

final class CallLogStore {
    private let fileURL: URL
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let lock = NSLock()

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("MicTimer", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("call-log.csv")

        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"
    }

    func append(_ record: CallRecord) {
        lock.lock()
        defer { lock.unlock() }

        let header = "date,time,minutes\n"
        let minutes = String(format: "%.2f", record.duration / 60)
        let line = "\(dateFormatter.string(from: record.start)),\(timeFormatter.string(from: record.start)),\(minutes)\n"

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? header.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }

        guard let data = line.data(using: .utf8), let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }
}
