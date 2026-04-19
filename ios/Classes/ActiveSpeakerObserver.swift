import AmazonChimeSDK

class ChimeActiveSpeakerObserver: ActiveSpeakerObserver {
    let chimeFlutterApi: ChimeFlutterApi

    var observerId: String = UUID().uuidString

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func activeSpeakerDidDetect(attendeeInfo: [AttendeeInfo]) {
        let ids = attendeeInfo.map { $0.attendeeId as String? }
        chimeFlutterApi.onActiveSpeakersChanged(attendeeIds: ids) { _ in }
    }
}
