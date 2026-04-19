import AmazonChimeSDK

class ChimeDataMessageObserver: DataMessageObserver {
    let chimeFlutterApi: ChimeFlutterApi
    /// The wildcard topic used to receive all data messages.
    let topic = "*"

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func dataMessageDidReceived(dataMessage: DataMessage) {
        let text = String(data: dataMessage.data, encoding: .utf8) ?? ""
        let msg = DataMessageMsg(
            topic: dataMessage.topic,
            data: text,
            senderAttendeeId: dataMessage.senderAttendeeId,
            senderExternalUserId: dataMessage.senderExternalUserId,
            timestampMs: dataMessage.timestampMs,
            throttled: dataMessage.throttled
        )
        chimeFlutterApi.onDataMessageReceived(message: msg) { _ in }
    }
}
