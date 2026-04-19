import AmazonChimeSDK

class ChimeContentShareObserver: ContentShareObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func contentShareDidStart() {
        chimeFlutterApi.onContentShareStateChanged(state: 0) { _ in }
    }

    func contentShareDidStop(status: ContentShareStatus) {
        chimeFlutterApi.onContentShareStateChanged(state: 1) { _ in }
    }
}
