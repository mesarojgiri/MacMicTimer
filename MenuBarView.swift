import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: model.isRecording ? "mic.fill" : "mic")
                    .foregroundStyle(model.isRecording ? .red : .secondary)
                VStack(alignment: .leading) {
                    Text(model.isRecording ? "Call in progress" : "MicTimer")
                        .font(.headline)
                    Text(model.isRecording ? formatDuration(model.elapsed) : "Microphone is inactive")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()
            Text("Today").font(.subheadline.bold())
            HStack {
                Label("Calls", systemImage: "phone")
                Spacer()
                Text("\(model.todayRecords.count)").foregroundStyle(.secondary)
            }
            HStack {
                Label("Total", systemImage: "clock")
                Spacer()
                Text(formatDuration(model.todayTotal)).foregroundStyle(.secondary)
            }

            if !model.todayRecords.isEmpty {
                Divider()
                ForEach(model.todayRecords.prefix(5)) { record in
                    HStack {
                        Text(record.start, style: .time)
                        Spacer()
                        Text(formatDuration(record.duration)).monospacedDigit()
                    }
                    .font(.caption)
                }
            }

            if model.microphonePermission == .denied {
                Divider()
                Text("Microphone access is required to detect calls.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Open Microphone Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
            }

            Divider()
            Toggle("Launch at Login", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            HStack {
                Button("Clear History") { model.deleteHistory() }
                Spacer()
                Button("Quit") { model.quit() }
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
