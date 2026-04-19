/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.AudioVideoObserver
import com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionStatus

class ChimeAudioVideoObserver(private val chimeFlutterApi: ChimeFlutterApi) : AudioVideoObserver {

    override fun onAudioSessionStarted(reconnecting: Boolean) {
        chimeFlutterApi.onAudioSessionStarted() {}
    }

    override fun onAudioSessionStopped(sessionStatus: MeetingSessionStatus) {
        chimeFlutterApi.onAudioSessionStopped() {}
    }

    override fun onAudioSessionStartedConnecting(reconnecting: Boolean) {
        chimeFlutterApi.onAudioSessionStartConnecting(reconnecting) {}
    }

    override fun onAudioSessionDropped() {
        chimeFlutterApi.onAudioSessionDropped() {}
    }

    override fun onAudioSessionCancelledReconnect() {
        chimeFlutterApi.onAudioSessionCancelledReconnect() {}
    }

    override fun onConnectionRecovered() {
        chimeFlutterApi.onConnectionQualityChanged(false) {}
    }

    override fun onConnectionBecamePoor() {
        chimeFlutterApi.onConnectionQualityChanged(true) {}
    }

    override fun onVideoSessionStarted(sessionStatus: MeetingSessionStatus) {
    }

    override fun onVideoSessionStartedConnecting() {
    }

    override fun onVideoSessionStopped(sessionStatus: MeetingSessionStatus) {
    }

    override fun onRemoteVideoSourceAvailable(sources: List<com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource>) {
        val msgs = sources.map { RemoteVideoSourceMsg(attendeeId = it.attendeeId) }
        chimeFlutterApi.onRemoteVideoSourcesAvailable(msgs) {}
    }

    override fun onRemoteVideoSourceUnavailable(sources: List<com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource>) {
        val msgs = sources.map { RemoteVideoSourceMsg(attendeeId = it.attendeeId) }
        chimeFlutterApi.onRemoteVideoSourcesUnavailable(msgs) {}
    }

    override fun onCameraSendAvailabilityUpdated(available: Boolean) {
    }
}