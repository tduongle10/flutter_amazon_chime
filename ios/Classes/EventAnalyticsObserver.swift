import AmazonChimeSDK

class ChimeEventAnalyticsObserver: EventAnalyticsObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func eventDidReceive(name: EventName, attributes: [AnyHashable: Any]) {
        var stringAttributes = [String: Any?]()
        for (key, value) in attributes {
            stringAttributes[String(describing: key)] = toPigeonValue(value)
        }
        chimeFlutterApi.onMeetingEventReceived(name: String(describing: name), attributes: stringAttributes) { _ in }
    }

    private func toPigeonValue(_ value: Any) -> Any? {
        switch value {
        case let s as String: return s
        case let n as NSNumber: return n
        case let b as Bool: return b
        default: return String(describing: value)
        }
    }
}
