import AmazonChimeSDK

class ChimeVideoTileObserver: VideoTileObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func videoTileDidAdd(tileState: VideoTileState) {
        let msg = VideoTileMsg(
            tileId: Int64(tileState.tileId),
            attendeeId: tileState.attendeeId,
            videoStreamContentHeight: Int64(tileState.videoStreamContentHeight),
            videoStreamContentWidth: Int64(tileState.videoStreamContentWidth),
            isLocalTile: tileState.isLocalTile,
            isDisplayOn: tileState.pauseState == .unpaused
        )
        chimeFlutterApi.onVideoTileAdded(tile: msg) { _ in }
    }

    func videoTileDidRemove(tileState: VideoTileState) {
        let msg = VideoTileMsg(
            tileId: Int64(tileState.tileId),
            attendeeId: tileState.attendeeId,
            videoStreamContentHeight: Int64(tileState.videoStreamContentHeight),
            videoStreamContentWidth: Int64(tileState.videoStreamContentWidth),
            isLocalTile: tileState.isLocalTile,
            isDisplayOn: false
        )
        chimeFlutterApi.onVideoTileRemoved(tile: msg) { _ in }
    }

    func videoTileDidPause(tileState: VideoTileState) {
        let msg = VideoTileMsg(
            tileId: Int64(tileState.tileId),
            attendeeId: tileState.attendeeId,
            videoStreamContentHeight: Int64(tileState.videoStreamContentHeight),
            videoStreamContentWidth: Int64(tileState.videoStreamContentWidth),
            isLocalTile: tileState.isLocalTile,
            isDisplayOn: false
        )
        chimeFlutterApi.onVideoTilePaused(tile: msg) { _ in }
    }

    func videoTileDidResume(tileState: VideoTileState) {
        let msg = VideoTileMsg(
            tileId: Int64(tileState.tileId),
            attendeeId: tileState.attendeeId,
            videoStreamContentHeight: Int64(tileState.videoStreamContentHeight),
            videoStreamContentWidth: Int64(tileState.videoStreamContentWidth),
            isLocalTile: tileState.isLocalTile,
            isDisplayOn: true
        )
        chimeFlutterApi.onVideoTileResumed(tile: msg) { _ in }
    }

    func videoTileSizeDidChange(tileState: VideoTileState) {}
}
