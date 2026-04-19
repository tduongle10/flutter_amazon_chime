import AVFoundation
import AmazonChimeSDK
import AmazonChimeSDKMedia
import Flutter
import Foundation
import UIKit
import ReplayKit

class MethodChannelCoordinator: NSObject, ChimeHostApi {
    let chimeFlutterApi: ChimeFlutterApi

    var realtimeObserver: ChimeRealtimeObserver?
    var audioVideoObserver: ChimeAudioVideoObserver?
    var videoTileObserver: ChimeVideoTileObserver?
    var activeSpeakerObserver: ChimeActiveSpeakerObserver?
    var contentShareObserver: ChimeContentShareObserver?
    var dataMessageObserver: ChimeDataMessageObserver?
    var metricsObserver: ChimeMetricsObserver?
    var eventAnalyticsObserver: ChimeEventAnalyticsObserver?

    /// Stores the App Group ID supplied at join time for IPC with the broadcast extension.
    private var appGroupId: String?

    /// Optional override for the broadcast extension's bundle identifier, supplied at join time.
    private var screenShareExtensionId: String?

    /// Stored max bitrate for local video (0 = SDK default).
    private var localVideoMaxBitrateKbps: Int = 0

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.chimeFlutterApi = ChimeFlutterApi(binaryMessenger: binaryMessenger)
        super.init()

        ChimeHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)

        // Auto-stop meeting when app is terminated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillTerminate() {
        if MeetingSession.shared.meetingSession != nil {
            try? self.stopMeeting()
        }
    }

    func manageAudioPermissions(completion: @escaping (Result<Bool, Error>) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            completion(.success(granted))
        }
    }

    func manageVideoPermissions(completion: @escaping (Result<Bool, Error>) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(.success(granted))
        }
    }

    func hasAudioPermissions() throws -> Bool {
        return AVAudioSession.sharedInstance().recordPermission == .granted
    }

    func hasVideoPermissions() throws -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func joinMeeting(joinInfo: JoinInfoMsg) throws {
        // Persist the AppGroup ID for subsequent screen share / stop operations.
        appGroupId = joinInfo.appGroupId
        screenShareExtensionId = joinInfo.screenShareExtensionId

        // Save meeting credentials to AppGroup UserDefaults for the Broadcast Extension handshake.
        if let groupId = appGroupId, let userDefaults = UserDefaults(suiteName: groupId) {
            userDefaults.set(joinInfo.externalMeetingId, forKey: "externalMeetingId")
            userDefaults.set(joinInfo.audioFallbackUrl, forKey: "audioFallbackUrl")
            userDefaults.set(joinInfo.audioHostUrl, forKey: "audioHostUrl")
            userDefaults.set(joinInfo.signalingUrl, forKey: "signalingUrl")
            userDefaults.set(joinInfo.turnControlUrl, forKey: "turnControlUrl")
            userDefaults.set(joinInfo.mediaRegion, forKey: "mediaRegion")
            userDefaults.set(joinInfo.meetingId, forKey: "meetingId")
            userDefaults.set(joinInfo.attendeeId, forKey: "attendeeId")
            userDefaults.set(joinInfo.externalUserId, forKey: "externalUserId")
            userDefaults.set(joinInfo.joinToken, forKey: "joinToken")
        }

        let meetingResponse = CreateMeetingResponse(
            meeting: Meeting(
                externalMeetingId: joinInfo.externalMeetingId ?? "",
                mediaPlacement: MediaPlacement(
                    audioFallbackUrl: joinInfo.audioFallbackUrl ?? "", audioHostUrl: joinInfo.audioHostUrl ?? "",
                    signalingUrl: joinInfo.signalingUrl ?? "", turnControlUrl: joinInfo.turnControlUrl ?? ""),
                mediaRegion: joinInfo.mediaRegion ?? "", meetingId: joinInfo.meetingId ?? ""))

        let attendeeResponse = CreateAttendeeResponse(
            attendee: Attendee(
                attendeeId: joinInfo.attendeeId ?? "", externalUserId: joinInfo.externalUserId ?? "", joinToken: joinInfo.joinToken ?? ""))

        let meetingSessionConfiguration = MeetingSessionConfiguration(
            createMeetingResponse: meetingResponse, createAttendeeResponse: attendeeResponse)

        let logger = ConsoleLogger(name: "MeetingSession Logger", level: LogLevel.DEBUG)

        let meetingSession = DefaultMeetingSession(
            configuration: meetingSessionConfiguration, logger: logger)

        self.configureAudioSession()

        MeetingSession.shared.meetingSession = meetingSession

        self.setupAudioVideoFacadeObservers()
        _ = MeetingSession.shared.startMeetingAudio()
    }

    func stopMeeting() throws {
        // Send a kill signal to the Broadcast Extension so the screen recording stops
        // without prompting the system "Stop Broadcast?" dialog.
        if let groupId = appGroupId, let userDefaults = UserDefaults(suiteName: groupId) {
            userDefaults.set(true, forKey: "stopBroadcast")

        }
        
        self.stopAudioVideoFacadeObservers()
        MeetingSession.shared.meetingSession?.audioVideo.stop()
        MeetingSession.shared.meetingSession = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func mute() throws -> Bool {
        return MeetingSession.shared.meetingSession?.audioVideo.realtimeLocalMute() ?? false
    }

    func unmute() throws -> Bool {
        return MeetingSession.shared.meetingSession?.audioVideo.realtimeLocalUnmute() ?? false
    }

    func startLocalVideo() throws {
        if localVideoMaxBitrateKbps > 0 {
            let config = LocalVideoConfiguration(maxBitRateKbps: UInt32(localVideoMaxBitrateKbps))
            try MeetingSession.shared.meetingSession?.audioVideo.startLocalVideo(config: config)
        } else {
            try MeetingSession.shared.meetingSession?.audioVideo.startLocalVideo()
        }
    }

    func switchCamera() throws {
        MeetingSession.shared.meetingSession?.audioVideo.switchCamera()
    }

    func activeCamera() throws -> String? {
        guard let device = MeetingSession.shared.meetingSession?.audioVideo.getActiveCamera() else {
            return nil
        }
        switch device.type {
        case .videoFrontCamera:
            return "front"
        case .videoBackCamera:
            return "back"
        default:
            return device.label
        }
    }

    func setLocalVideoMaxBitrate(maxBitrateKbps: Int64) throws {
        localVideoMaxBitrateKbps = Int(maxBitrateKbps)
        // If local video is already active, restart it with the new config.
        if MeetingSession.shared.meetingSession != nil {
            try startLocalVideo()
        }
    }

    func stopLocalVideo() throws {
        MeetingSession.shared.meetingSession?.audioVideo.stopLocalVideo()
    }

    func initialAudioSelection() throws -> String? {
        return MeetingSession.shared.meetingSession?.audioVideo.getActiveAudioDevice()?.label
    }

    func listAudioDevices() throws -> [String?] {
        guard let audioDevices = MeetingSession.shared.meetingSession?.audioVideo.listAudioDevices() else {
            return []
        }
        return audioDevices.map { $0.label }
    }

    func updateAudioDevice(deviceName: String) throws -> Bool {
        guard let audioDevices = MeetingSession.shared.meetingSession?.audioVideo.listAudioDevices() else {
            return false
        }

        for dev in audioDevices {
            if deviceName == dev.label {
                MeetingSession.shared.meetingSession?.audioVideo.chooseAudioDevice(mediaDevice: dev)
                return true
            }
        }
        return false
    }

    private func setupAudioVideoFacadeObservers() {
        self.realtimeObserver = ChimeRealtimeObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.realtimeObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addRealtimeObserver(observer: obs)
        }

        self.audioVideoObserver = ChimeAudioVideoObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.audioVideoObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addAudioVideoObserver(observer: obs)
        }

        self.videoTileObserver = ChimeVideoTileObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.videoTileObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addVideoTileObserver(observer: obs)
        }

        self.activeSpeakerObserver = ChimeActiveSpeakerObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.activeSpeakerObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addActiveSpeakerObserver(
                policy: DefaultActiveSpeakerPolicy(),
                observer: obs)
        }

        self.contentShareObserver = ChimeContentShareObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.contentShareObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addContentShareObserver(observer: obs)
        }

        self.dataMessageObserver = ChimeDataMessageObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.dataMessageObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addRealtimeDataMessageObserver(topic: obs.topic, observer: obs)
        }

        self.metricsObserver = ChimeMetricsObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.metricsObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addMetricsObserver(observer: obs)
        }

        self.eventAnalyticsObserver = ChimeEventAnalyticsObserver(chimeFlutterApi: self.chimeFlutterApi)
        if let obs = self.eventAnalyticsObserver {
            MeetingSession.shared.meetingSession?.audioVideo.addEventAnalyticsObserver(observer: obs)
        }
    }

    func stopAudioVideoFacadeObservers() {
        if let rtObserver = self.realtimeObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeRealtimeObserver(observer: rtObserver)
            self.realtimeObserver = nil
        }
        if let avObserver = self.audioVideoObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeAudioVideoObserver(observer: avObserver)
            self.audioVideoObserver = nil
        }
        if let vtObserver = self.videoTileObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeVideoTileObserver(observer: vtObserver)
            self.videoTileObserver = nil
        }
        if let asObserver = self.activeSpeakerObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeActiveSpeakerObserver(observer: asObserver)
            self.activeSpeakerObserver = nil
        }
        if let csObserver = self.contentShareObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeContentShareObserver(observer: csObserver)
            self.contentShareObserver = nil
        }
        if let dmObserver = self.dataMessageObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeRealtimeDataMessageObserverFromTopic(topic: dmObserver.topic)
            self.dataMessageObserver = nil
        }
        if let mObserver = self.metricsObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeMetricsObserver(observer: mObserver)
            self.metricsObserver = nil
        }
        if let eaObserver = self.eventAnalyticsObserver {
            MeetingSession.shared.meetingSession?.audioVideo.removeEventAnalyticsObserver(observer: eaObserver)
            self.eventAnalyticsObserver = nil
        }
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                AVAudioSession.Category.playAndRecord,
                options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setMode(.voiceChat)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            let logger = ConsoleLogger(name: "AudioSession", level: LogLevel.ERROR)
            logger.error(msg: "Failed to configure audio session: \(error)")
        }
    }

    func sendDataMessage(topic: String, data: String, lifetimeMs: Int64) throws {
        guard let audioVideo = MeetingSession.shared.meetingSession?.audioVideo else { return }
        let dataBytes = data.data(using: .utf8) ?? Data()
        try audioVideo.realtimeSendDataMessage(topic: topic, data: dataBytes, lifetimeMs: Int32(lifetimeMs))
    }

    func updateVideoSourceSubscriptions(toAdd: [RemoteVideoSourceMsg?], toRemove: [RemoteVideoSourceMsg?]) throws {
        guard let audioVideo = MeetingSession.shared.meetingSession?.audioVideo else { return }
        var addedOrUpdated = [RemoteVideoSource: VideoSubscriptionConfiguration]()
        for msg in toAdd.compactMap({ $0 }) {
            if let attendeeId = msg.attendeeId {
                let source = RemoteVideoSource()
                source.attendeeId = attendeeId
                addedOrUpdated[source] = VideoSubscriptionConfiguration()
            }
        }
        let removed = toRemove.compactMap { msg -> RemoteVideoSource? in
            guard let attendeeId = msg?.attendeeId else { return nil }
            let source = RemoteVideoSource()
            source.attendeeId = attendeeId
            return source
        }
        audioVideo.updateVideoSourceSubscriptions(addedOrUpdated: addedOrUpdated, removed: removed)
    }

    /// Resolves the broadcast extension's bundle ID in order of precedence:
    ///   1. `screenShareExtensionId` on the `JoinInfoMsg` passed at join time.
    ///   2. `ChimeScreenShareExtension` key in the main app's Info.plist.
    ///   3. Default suffix `<mainBundleId>.ScreenShareExt`.
    /// Returns nil if none of these can be resolved.
    private func resolveScreenShareExtensionId() -> String? {
        if let id = screenShareExtensionId, !id.isEmpty {
            return id
        }
        if let id = Bundle.main.object(forInfoDictionaryKey: "ChimeScreenShareExtension") as? String,
           !id.isEmpty {
            return id
        }
        if let bundleId = Bundle.main.bundleIdentifier {
            return bundleId + ".ScreenShareExt"
        }
        return nil
    }

    /// Programmatically triggers the system broadcast picker for the resolved extension.
    private func triggerBroadcastPicker(extensionId: String) {
        let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        broadcastPicker.preferredExtension = extensionId
        broadcastPicker.showsMicrophoneButton = false

        // RPSystemBroadcastPickerView exposes no public API to open its sheet programmatically,
        // so we reach into its subview hierarchy to send a touch-up-inside action. If Apple changes
        // this hierarchy, the picker will simply need a user tap instead of opening instantly.
        if let button = broadcastPicker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.sendActions(for: .touchUpInside)
        }
    }

    func startScreenShare() throws {
        guard let extensionId = resolveScreenShareExtensionId() else {
            let logger = ConsoleLogger(name: "ScreenShareLogger", level: LogLevel.ERROR)
            logger.error(msg: "Cannot start screen share: broadcast extension bundle ID could not be resolved. Set `screenShareExtensionId` on JoinInfo or add the `ChimeScreenShareExtension` key to Info.plist.")
            return
        }

        // Clear the stop flag so the extension doesn't immediately terminate on start.
        if let groupId = appGroupId, let userDefaults = UserDefaults(suiteName: groupId) {
            userDefaults.set(false, forKey: "stopBroadcast")
        }

        triggerBroadcastPicker(extensionId: extensionId)
    }

    func stopScreenShare() throws {
        guard let extensionId = resolveScreenShareExtensionId() else {
            let logger = ConsoleLogger(name: "ScreenShareLogger", level: LogLevel.ERROR)
            logger.error(msg: "Cannot stop screen share: broadcast extension bundle ID could not be resolved.")
            return
        }

        // Natively trigger the Apple System Dialog for "Stop Broadcasting"
        triggerBroadcastPicker(extensionId: extensionId)

        let logger = ConsoleLogger(name: "ScreenShareLogger", level: LogLevel.INFO)
        logger.info(msg: "Invoked system broadcast picker view for programmatic stop dialog.")
    }
}
