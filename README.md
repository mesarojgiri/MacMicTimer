# MicTimer

MicTimer is a native macOS menu-bar app that measures time while the system input device is active.

## Download and run

Download MacMicTimer.app.zip and run it directly. 

## Build and run

1. Open `MicTimer.xcodeproj` in Xcode 14 or newer on an Apple Silicon Mac.
2. Select the **MicTimer** scheme and your Mac as the run destination.
3. Build and run. Grant microphone access when prompted.
4. Start a browser or conferencing call that uses the microphone. The menu-bar timer starts and stops with microphone activity.

MicTimer registers itself as a login item on first launch, so it will start automatically after a restart. Use the **Launch at Login** toggle in the menu to disable or re-enable this.

Call history is stored at `~/Library/Application Support/MicTimer/calls.json`. A separate CSV log is stored at `~/Library/Application Support/MicTimer/call-log.csv` with the columns `date,time,minutes`. Microphone sessions shorter than two seconds are ignored and are not added to either log or shown as notifications. The app is an agent app, so it runs in the menu bar without a Dock icon.

The detector observes the default input device's Core Audio running state. This intentionally measures microphone activity, not a specific calling platform, so rates or billing are not assumed.
 
