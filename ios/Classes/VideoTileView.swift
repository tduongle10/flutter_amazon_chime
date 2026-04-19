import AmazonChimeSDK
import Flutter
import Foundation

class VideoTileView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _tileId: Int?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) {
        _view = DefaultVideoRenderView()
        super.init()

        // Receive tileId as a param.
        guard let tileId = args as? Int else { return }
        _tileId = tileId
        guard let videoRenderView = _view as? VideoRenderView else { return }

        // Bind view to VideoView
        MeetingSession.shared.meetingSession?.audioVideo.bindVideoView(
            videoView: videoRenderView, tileId: tileId)

        // Fix aspect ratio
        _view.contentMode = .scaleAspectFit

        // Declare _view as UIView for Flutter interpretation
        _view = _view as UIView
    }

    func view() -> UIView {
        return _view
    }

    func dispose() {
        if let tileId = _tileId {
            MeetingSession.shared.meetingSession?.audioVideo.unbindVideoView(tileId: tileId)
        }
        _tileId = nil
    }
}
