import AmazonChimeSDK

class ChimeAudioVideoObserver: AudioVideoObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func audioSessionDidStartConnecting(reconnecting: Bool) {
        chimeFlutterApi.onAudioSessionStartConnecting(reconnecting: reconnecting) { _ in }
    }

    func audioSessionDidStart(reconnecting: Bool) {
        chimeFlutterApi.onAudioSessionStarted { _ in }
    }

    func audioSessionDidDrop() {
        chimeFlutterApi.onAudioSessionDropped { _ in }
    }

    func audioSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {
        chimeFlutterApi.onAudioSessionStopped { _ in }
    }

    func audioSessionDidCancelReconnect() {
        chimeFlutterApi.onAudioSessionCancelledReconnect { _ in }
    }

    func connectionDidRecover() {
        chimeFlutterApi.onConnectionQualityChanged(isPoor: false) { _ in }
    }

    func connectionDidBecomePoor() {
        chimeFlutterApi.onConnectionQualityChanged(isPoor: true) { _ in }
    }

    func videoSessionDidStartConnecting() {}

    func videoSessionDidStartWithStatus(sessionStatus: MeetingSessionStatus) {}

    func videoSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {}

    func remoteVideoSourcesDidBecomeAvailable(sources: [RemoteVideoSource]) {
        let msgs = sources.map { RemoteVideoSourceMsg(attendeeId: $0.attendeeId) }
        chimeFlutterApi.onRemoteVideoSourcesAvailable(sources: msgs) { _ in }
    }

    func remoteVideoSourcesDidBecomeUnavailable(sources: [RemoteVideoSource]) {
        let msgs = sources.map { RemoteVideoSourceMsg(attendeeId: $0.attendeeId) }
        chimeFlutterApi.onRemoteVideoSourcesUnavailable(sources: msgs) { _ in }
    }

    func cameraSendAvailabilityDidChange(available: Bool) {}
}
