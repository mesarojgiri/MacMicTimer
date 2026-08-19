import Foundation
import SwiftUI
import AppKit
import ServiceManagement

@MainActor
final class AppModel: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var records: [CallRecord] = []
    @Published private(set) var microphonePermission: PermissionState = .unknown
    @Published private(set) var launchAtLogin = false

    private let monitor = MicrophoneMonitor()
    private let history = HistoryStore()
    private let callLog = CallLogStore()
    private let notifications = NotificationManager()
    private static let minimumCallDuration: TimeInterval = 2
    private var activeStart: Date?
    private var ticker: Timer?

    enum PermissionState: Equatable {
        case unknown, granted, denied
    }

    override init() {
        records = history.load().filter { $0.duration >= Self.minimumCallDuration }
        var launchAtLoginStatus = SMAppService.mainApp.status == .enabled
        if !launchAtLoginStatus {
            try? SMAppService.mainApp.register()
            launchAtLoginStatus = SMAppService.mainApp.status == .enabled
        }
        launchAtLogin = launchAtLoginStatus
        super.init()
        monitor.onPermissionChange = { [weak self] granted in
            Task { @MainActor in
                self?.microphonePermission = granted ? .granted : .denied
            }
        }
        monitor.onActivityChange = { [weak self] active in
            Task { @MainActor in self?.handleMicrophoneActivity(active) }
        }
        monitor.start()
    }

    var todayRecords: [CallRecord] {
        records.filter { Calendar.current.isDateInToday($0.start) }
    }

    var todayTotal: TimeInterval {
        todayRecords.reduce(0) { $0 + $1.duration }
    }

    var menuBarTitle: String {
        isRecording ? formatDuration(elapsed) : "MicTimer"
    }

    func requestMicrophoneAccess() {
        monitor.requestAccess()
    }

    func deleteHistory() {
        records.removeAll()
        history.save(records)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func handleMicrophoneActivity(_ active: Bool) {
        guard microphonePermission != .denied else { return }
        if active, !isRecording {
            activeStart = Date()
            elapsed = 0
            isRecording = true
            startTicker()
        } else if !active, isRecording {
            finishCall(at: Date())
        }
    }

    private func finishCall(at end: Date) {
        guard let start = activeStart else { return }
        let record = CallRecord(start: start, end: end)
        activeStart = nil
        isRecording = false
        elapsed = 0
        ticker?.invalidate()
        ticker = nil

        guard record.duration >= Self.minimumCallDuration else { return }
        records.insert(record, at: 0)
        history.save(records)
        callLog.append(record)
        notifications.send(for: record)
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(timeInterval: 1,
                                      target: self,
                                      selector: #selector(updateElapsed),
                                      userInfo: nil,
                                      repeats: true)
    }

    @objc private func updateElapsed() {
        guard let start = activeStart else { return }
        elapsed = Date().timeIntervalSince(start)
    }

    deinit { ticker?.invalidate() }
}

func formatDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = max(0, Int(duration.rounded()))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
                     : String(format: "%02d:%02d", minutes, seconds)
}
