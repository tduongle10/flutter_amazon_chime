/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
import AmazonChimeSDK
import AmazonChimeSDKMedia
import Foundation

// Singleton Pattern Class
class MeetingSession {
    static let shared = MeetingSession()
    
    var meetingSession: DefaultMeetingSession?
    
    let audioVideoConfig = AudioVideoConfiguration()
    private let logger = ConsoleLogger(name: "MeetingSession")
    
    private init() {}
    
    func startMeetingAudio() -> Bool {
        return startAudioVideoConnection()
    }

    private func startAudioVideoConnection() -> Bool {
        do {
            try meetingSession?.audioVideo.start()
            meetingSession?.audioVideo.startRemoteVideo()
        } catch PermissionError.audioPermissionError {
            logger.error(msg: "Audio permissions error.")
            return false
        } catch {
            logger.error(msg: "Error starting the Meeting: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
}
