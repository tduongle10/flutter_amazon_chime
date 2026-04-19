/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoPauseState
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoTileObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoTileState

class ChimeVideoTileObserver(private val chimeFlutterApi: ChimeFlutterApi) : VideoTileObserver {

    override fun onVideoTileAdded(tileState: VideoTileState) {
        val tileMsg = VideoTileMsg(
            tileId = tileState.tileId.toLong(),
            attendeeId = tileState.attendeeId,
            videoStreamContentHeight = tileState.videoStreamContentHeight.toLong(),
            videoStreamContentWidth = tileState.videoStreamContentWidth.toLong(),
            isLocalTile = tileState.isLocalTile,
            isDisplayOn = tileState.pauseState == VideoPauseState.Unpaused
        )
        chimeFlutterApi.onVideoTileAdded(tileMsg) {}
    }

    override fun onVideoTileRemoved(tileState: VideoTileState) {
        val tileMsg = VideoTileMsg(
            tileId = tileState.tileId.toLong(),
            attendeeId = tileState.attendeeId,
            videoStreamContentHeight = tileState.videoStreamContentHeight.toLong(),
            videoStreamContentWidth = tileState.videoStreamContentWidth.toLong(),
            isLocalTile = tileState.isLocalTile,
            isDisplayOn = false
        )
        chimeFlutterApi.onVideoTileRemoved(tileMsg) {}
    }

    override fun onVideoTilePaused(tileState: VideoTileState) {
        val tileMsg = VideoTileMsg(
            tileId = tileState.tileId.toLong(),
            attendeeId = tileState.attendeeId,
            videoStreamContentHeight = tileState.videoStreamContentHeight.toLong(),
            videoStreamContentWidth = tileState.videoStreamContentWidth.toLong(),
            isLocalTile = tileState.isLocalTile,
            isDisplayOn = false
        )
        chimeFlutterApi.onVideoTilePaused(tileMsg) {}
    }

    override fun onVideoTileResumed(tileState: VideoTileState) {
        val tileMsg = VideoTileMsg(
            tileId = tileState.tileId.toLong(),
            attendeeId = tileState.attendeeId,
            videoStreamContentHeight = tileState.videoStreamContentHeight.toLong(),
            videoStreamContentWidth = tileState.videoStreamContentWidth.toLong(),
            isLocalTile = tileState.isLocalTile,
            isDisplayOn = true
        )
        chimeFlutterApi.onVideoTileResumed(tileMsg) {}
    }

    override fun onVideoTileSizeChanged(tileState: VideoTileState) {
    }
}