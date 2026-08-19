import Foundation
import UserNotifications

final class NotificationManager {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func send(for record: CallRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Call Ended"
        content.body = "Duration: \(formatDuration(record.duration))"
        content.sound = .default
        let request = UNNotificationRequest(identifier: record.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
