import AmazonChimeSDK

class ChimeMetricsObserver: MetricsObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func metricsDidReceive(metrics: [AnyHashable: Any]) {
        var stringMetrics = [String: Any?]()
        for (key, value) in metrics {
            stringMetrics[String(describing: key)] = toPigeonValue(value)
        }
        chimeFlutterApi.onMeetingMetricsReceived(metrics: stringMetrics) { _ in }
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
