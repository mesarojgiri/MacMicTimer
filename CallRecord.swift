import Foundation

struct CallRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date

    init(id: UUID = UUID(), start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }

    var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }
}
