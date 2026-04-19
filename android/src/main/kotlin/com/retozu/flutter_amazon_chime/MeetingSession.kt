/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.session.DefaultMeetingSession
import com.amazonaws.services.chime.sdk.meetings.audiovideo.AudioVideoObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.AudioVideoFacade
import com.amazonaws.services.chime.sdk.meetings.audiovideo.audio.activespeakerdetector.ActiveSpeakerObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.audio.activespeakerpolicy.DefaultActiveSpeakerPolicy
import com.amazonaws.services.chime.sdk.meetings.audiovideo.contentshare.ContentShareObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.metric.MetricsObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoTileObserver
import com.amazonaws.services.chime.sdk.meetings.analytics.EventAnalyticsObserver
import com.amazonaws.services.chime.sdk.meetings.realtime.RealtimeObserver
import com.amazonaws.services.chime.sdk.meetings.realtime.datamessage.DataMessageObserver
import com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger

object MeetingSessionManager {
    private val meetingSessionlogger: ConsoleLogger = ConsoleLogger()

    var realtimeObserver: RealtimeObserver? = null
    var videoTileObserver: VideoTileObserver? = null
    var audioVideoObserver: AudioVideoObserver? = null
    var activeSpeakerObserver: ActiveSpeakerObserver? = null
    var contentShareObserver: ContentShareObserver? = null
    var dataMessageObserver: DataMessageObserver? = null
    var metricsObserver: MetricsObserver? = null
    var eventAnalyticsObserver: EventAnalyticsObserver? = null

    var meetingSession: DefaultMeetingSession? = null

    fun startMeeting(
        realtimeObserver: RealtimeObserver? = null,
        videoTileObserver: VideoTileObserver? = null,
        audioVideoObserver: AudioVideoObserver? = null,
        activeSpeakerObserver: ActiveSpeakerObserver? = null,
        contentShareObserver: ContentShareObserver? = null,
        dataMessageObserver: DataMessageObserver? = null,
        metricsObserver: MetricsObserver? = null,
        eventAnalyticsObserver: EventAnalyticsObserver? = null
    ) {
        val audioVideo: AudioVideoFacade = meetingSession?.audioVideo ?: return
        addObservers(realtimeObserver, videoTileObserver, audioVideoObserver, activeSpeakerObserver, contentShareObserver, dataMessageObserver, metricsObserver, eventAnalyticsObserver)
        audioVideo.start()
        audioVideo.startRemoteVideo()
    }

    fun stop() {
        meetingSession?.audioVideo?.stopRemoteVideo()
        meetingSession?.audioVideo?.stop()
        removeObservers()
        meetingSession = null
    }

    private fun addObservers(
        realtimeObserver: RealtimeObserver?,
        videoTileObserver: VideoTileObserver?,
        audioVideoObserver: AudioVideoObserver?,
        activeSpeakerObserver: ActiveSpeakerObserver?,
        contentShareObserver: ContentShareObserver?,
        dataMessageObserver: DataMessageObserver?,
        metricsObserver: MetricsObserver?,
        eventAnalyticsObserver: EventAnalyticsObserver?
    ) {
        val audioVideo: AudioVideoFacade = meetingSession?.audioVideo ?: return
        realtimeObserver?.let {
            audioVideo.addRealtimeObserver(it)
            this.realtimeObserver = realtimeObserver
            meetingSessionlogger.debug("RealtimeObserver", "RealtimeObserver initialized")
        }
        audioVideoObserver?.let {
            audioVideo.addAudioVideoObserver(it)
            this.audioVideoObserver = audioVideoObserver
            meetingSessionlogger.debug("AudioVideoObserver", "AudioVideoObserver initialized")
        }
        videoTileObserver?.let {
            audioVideo.addVideoTileObserver(videoTileObserver)
            this.videoTileObserver = videoTileObserver
            meetingSessionlogger.debug("VideoTileObserver", "VideoTileObserver initialized")
        }
        activeSpeakerObserver?.let {
            audioVideo.addActiveSpeakerObserver(DefaultActiveSpeakerPolicy(), it)
            this.activeSpeakerObserver = it
            meetingSessionlogger.debug("ActiveSpeakerObserver", "ActiveSpeakerObserver initialized")
        }
        contentShareObserver?.let {
            audioVideo.addContentShareObserver(it)
            this.contentShareObserver = it
            meetingSessionlogger.debug("ContentShareObserver", "ContentShareObserver initialized")
        }
        dataMessageObserver?.let {
            val topic = (it as? ChimeDataMessageObserver)?.topic ?: "*"
            audioVideo.addRealtimeDataMessageObserver(topic, it)
            this.dataMessageObserver = it
            meetingSessionlogger.debug("DataMessageObserver", "DataMessageObserver initialized")
        }
        metricsObserver?.let {
            audioVideo.addMetricsObserver(it)
            this.metricsObserver = it
            meetingSessionlogger.debug("MetricsObserver", "MetricsObserver initialized")
        }
        eventAnalyticsObserver?.let {
            audioVideo.addEventAnalyticsObserver(it)
            this.eventAnalyticsObserver = it
            meetingSessionlogger.debug("EventAnalyticsObserver", "EventAnalyticsObserver initialized")
        }
    }

    private fun removeObservers() {
        realtimeObserver?.let {
            meetingSession?.audioVideo?.removeRealtimeObserver(it)
            realtimeObserver = null
        }
        audioVideoObserver?.let {
            meetingSession?.audioVideo?.removeAudioVideoObserver(it)
            audioVideoObserver = null
        }
        videoTileObserver?.let {
            meetingSession?.audioVideo?.removeVideoTileObserver(it)
            videoTileObserver = null
        }
        activeSpeakerObserver?.let { obs ->
            meetingSession?.audioVideo?.removeActiveSpeakerObserver(obs)
            activeSpeakerObserver = null
        }
        contentShareObserver?.let {
            meetingSession?.audioVideo?.removeContentShareObserver(it)
            contentShareObserver = null
        }
        val dmTopic = (dataMessageObserver as? ChimeDataMessageObserver)?.topic
        if (dmTopic != null) {
            meetingSession?.audioVideo?.removeRealtimeDataMessageObserverFromTopic(dmTopic)
        }
        dataMessageObserver = null
        metricsObserver?.let {
            meetingSession?.audioVideo?.removeMetricsObserver(it)
            metricsObserver = null
        }
        eventAnalyticsObserver?.let {
            meetingSession?.audioVideo?.removeEventAnalyticsObserver(it)
            eventAnalyticsObserver = null
        }
    }
}
