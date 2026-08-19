import SwiftUI

@main
struct MicTimerApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: appModel)
        } label: {
            Label {
                Text(appModel.menuBarTitle)
            } icon: {
                Image(systemName: appModel.isRecording ? "mic.fill" : "mic")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
