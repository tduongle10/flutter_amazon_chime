/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import android.content.Context
import android.view.View
import io.flutter.plugin.platform.PlatformView
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.DefaultVideoRenderView
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoScalingType
import com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger

internal class VideoTileView(context: Context?, val creationParams: Int?) : PlatformView {
    private val view: DefaultVideoRenderView
    private val videoTileViewLogger: ConsoleLogger = ConsoleLogger()

    override fun getView(): View {
        return view
    }

    override fun dispose() {
        if (creationParams != null) {
            try {
                MeetingSessionManager.meetingSession?.audioVideo?.unbindVideoView(creationParams)
                videoTileViewLogger.info("VideoTileView", "Successfully unbound video tile $creationParams")
            } catch (e: Exception) {
                videoTileViewLogger.error("VideoTileView", "Error unbinding video tile $creationParams: ${e.message}")
            }
        }
    }

    init {
        view = DefaultVideoRenderView(context ?: throw IllegalArgumentException("Context must not be null"))
        view.scalingType = VideoScalingType.AspectFit
        if (creationParams != null) {
            MeetingSessionManager.meetingSession?.audioVideo?.bindVideoView(view, creationParams)
                ?: videoTileViewLogger.error("VideoTileView", "Error while binding video view.")
        }
    }
}