import AVFoundation
import CoreAudio
import Foundation

final class MicrophoneMonitor {
    var onActivityChange: ((Bool) -> Void)?
    var onPermissionChange: ((Bool) -> Void)?

    private var deviceID = AudioDeviceID(0)
    private var pollTimer: Timer?
    private var lastActivity = false
    private var listening = false

    func start() {
        requestAccess()
    }

    func requestAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            onPermissionChange?(true)
            installListeners()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.onPermissionChange?(granted)
                    if granted { self?.installListeners() }
                }
            }
        default:
            onPermissionChange?(false)
        }
    }

    private func installListeners() {
        guard !listening else { return }
        listening = true
        deviceID = defaultInputDevice()
        addDeviceListener()
        addDefaultDeviceListener()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.publishIfChanged(self?.inputDeviceIsRunning() ?? false)
        }
        if let pollTimer { RunLoop.main.add(pollTimer, forMode: .common) }
        publishIfChanged(inputDeviceIsRunning())
    }

    private func defaultInputDevice() -> AudioDeviceID {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                   mScope: kAudioObjectPropertyScopeGlobal,
                                                   mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return device
    }

    private func inputDeviceIsRunning() -> Bool {
        guard deviceID != 0 else { return false }
        var running = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                                                   mScope: kAudioObjectPropertyScopeGlobal,
                                                   mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running)
        return status == noErr && running != 0
    }

    private func publishIfChanged(_ active: Bool) {
        guard active != lastActivity else { return }
        lastActivity = active
        onActivityChange?(active)
    }

    private func addDeviceListener() {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                                                   mScope: kAudioObjectPropertyScopeGlobal,
                                                   mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(deviceID, &address, DispatchQueue.main) { [weak self] _, _ in
            self?.publishIfChanged(self?.inputDeviceIsRunning() ?? false)
        }
    }

    private func addDefaultDeviceListener() {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                   mScope: kAudioObjectPropertyScopeGlobal,
                                                   mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main) { [weak self] _, _ in
            guard let self else { return }
            self.deviceID = self.defaultInputDevice()
            self.addDeviceListener()
            self.publishIfChanged(self.inputDeviceIsRunning())
        }
    }

    deinit { pollTimer?.invalidate() }
}
