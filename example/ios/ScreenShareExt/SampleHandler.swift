import ReplayKit
import AmazonChimeSDK
import AmazonChimeSDKMedia

class SampleHandler: RPBroadcastSampleHandler {
    let logger = ConsoleLogger(name: "ScreenShareExt")
    var replayKitSource: ReplayKitSource?
    var meetingSession: DefaultMeetingSession?
    var killTimer: Timer?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        logger.info(msg: "Broadcast started. Initializing Chime SDK...")
        let userDefaults = UserDefaults(suiteName: "group.com.retozu.flutterChimeExample.screenshare")
        
        guard let externalMeetingId = userDefaults?.string(forKey: "externalMeetingId"),
              let meetingId = userDefaults?.string(forKey: "meetingId"),
              let mediaRegion = userDefaults?.string(forKey: "mediaRegion"),
              let audioFallbackUrl = userDefaults?.string(forKey: "audioFallbackUrl"),
              let audioHostUrl = userDefaults?.string(forKey: "audioHostUrl"),
              let signalingUrl = userDefaults?.string(forKey: "signalingUrl"),
              let turnControlUrl = userDefaults?.string(forKey: "turnControlUrl"),
              let attendeeId = userDefaults?.string(forKey: "attendeeId"),
              let externalUserId = userDefaults?.string(forKey: "externalUserId"),
              let joinToken = userDefaults?.string(forKey: "joinToken") else {
            logger.error(msg: "Failed to read Meeting Credentials from AppGroup UserDefaults.")
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "No active meeting to share to."]))
            return
        }

        // Start IPC Poller to listen for the Flutter Kill Switch
        killTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            let defaults = UserDefaults(suiteName: "group.com.retozu.flutterChimeExample.screenshare")
            if defaults?.bool(forKey: "stopBroadcast") == true {
                self?.finishBroadcastWithError(NSError(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Stopped from Flutter App"]))
            }
        }

        let meetingResponse = CreateMeetingResponse(
            meeting: Meeting(
                externalMeetingId: externalMeetingId,
                mediaPlacement: MediaPlacement(
                    audioFallbackUrl: audioFallbackUrl, audioHostUrl: audioHostUrl,
                    signalingUrl: signalingUrl, turnControlUrl: turnControlUrl),
                mediaRegion: mediaRegion, meetingId: meetingId))

        let attendeeResponse = CreateAttendeeResponse(
            attendee: Attendee(
                attendeeId: attendeeId, externalUserId: externalUserId, joinToken: joinToken))

        let meetingSessionConfiguration = MeetingSessionConfiguration(
            createMeetingResponse: meetingResponse, createAttendeeResponse: attendeeResponse)
            
        meetingSession = DefaultMeetingSession(configuration: meetingSessionConfiguration, logger: logger)
        
        replayKitSource = ReplayKitSource(logger: logger)
        if let source = replayKitSource {
            let contentShareSource = ContentShareSource()
            contentShareSource.videoSource = source
            
            // CRITICAL: We must physically bind the socket connection in the background process
            do {
                try meetingSession?.audioVideo.start()
            } catch {
                logger.error(msg: "Failed to establish background Chime socket connection.")
            }
            
            // Command the stream to consume ReplayKit frames
            meetingSession?.audioVideo.startContentShare(source: contentShareSource)
        }
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast.
    }
    
    override func broadcastFinished() {
        logger.info(msg: "Broadcast finished. Stopping Chime session...")
        killTimer?.invalidate()
        killTimer = nil
        meetingSession?.audioVideo.stopContentShare()
        meetingSession?.audioVideo.stop()
        meetingSession = nil
        replayKitSource = nil
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        // High-frequency check for the stop signal to guarantee immediate termination
        // when leaving the meeting from the Flutter app.
        if let defaults = UserDefaults(suiteName: "group.com.retozu.flutterChimeExample.screenshare"),
           defaults.bool(forKey: "stopBroadcast") == true {
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Stopped from Flutter App"]))
            return
        }

        switch sampleBufferType {
        case RPSampleBufferType.video:
            replayKitSource?.processSampleBuffer(sampleBuffer: sampleBuffer, type: sampleBufferType)
        case RPSampleBufferType.audioApp:
            replayKitSource?.processSampleBuffer(sampleBuffer: sampleBuffer, type: sampleBufferType)
            break
        case RPSampleBufferType.audioMic:
            break
        @unknown default:
            break
        }
    }
}
