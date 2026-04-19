package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.AttendeeInfo
import com.amazonaws.services.chime.sdk.meetings.audiovideo.audio.activespeakerdetector.ActiveSpeakerObserver

class ChimeActiveSpeakerObserver(private val chimeFlutterApi: ChimeFlutterApi) : ActiveSpeakerObserver {
    override val scoreCallbackIntervalMs: Int? = null

    override fun onActiveSpeakerDetected(attendeeInfo: Array<AttendeeInfo>) {
        val ids = attendeeInfo.map { it.attendeeId as String? }
        chimeFlutterApi.onActiveSpeakersChanged(ids) {}
    }

    override fun onActiveSpeakerScoreChanged(scores: Map<AttendeeInfo, Double>) {
        // not forwarded
    }
}
