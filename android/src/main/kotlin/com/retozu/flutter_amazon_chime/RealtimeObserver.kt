/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.AttendeeInfo
import com.amazonaws.services.chime.sdk.meetings.audiovideo.VolumeUpdate
import com.amazonaws.services.chime.sdk.meetings.audiovideo.SignalUpdate
import com.amazonaws.services.chime.sdk.meetings.realtime.RealtimeObserver

class ChimeRealtimeObserver(private val chimeFlutterApi: ChimeFlutterApi) : RealtimeObserver {

    override fun onVolumeChanged(volumeUpdates: Array<VolumeUpdate>) {
        val msgs = volumeUpdates.map { u ->
            AttendeeVolumeMsg(
                attendeeId = u.attendeeInfo.attendeeId,
                externalUserId = u.attendeeInfo.externalUserId,
                volume = u.volumeLevel.value.toLong()
            )
        }
        chimeFlutterApi.onAttendeesVolumeChanged(msgs) {}
    }

    override fun onSignalStrengthChanged(signalUpdates: Array<SignalUpdate>) {
        val msgs = signalUpdates.map { u ->
            AttendeeSignalMsg(
                attendeeId = u.attendeeInfo.attendeeId,
                externalUserId = u.attendeeInfo.externalUserId,
                signalStrength = u.signalStrength.value.toLong()
            )
        }
        chimeFlutterApi.onAttendeesSignalChanged(msgs) {}
    }

    override fun onAttendeesJoined(attendeeInfo: Array<AttendeeInfo>) {
        attendeeInfo.forEach {
            chimeFlutterApi.onAttendeeJoined(AttendeeMsg(it.attendeeId, it.externalUserId)) {}
        }
    }

    override fun onAttendeesLeft(attendeeInfo: Array<AttendeeInfo>) {
        attendeeInfo.forEach {
            chimeFlutterApi.onAttendeeLeft(AttendeeMsg(it.attendeeId, it.externalUserId)) {}
        }
    }

    override fun onAttendeesDropped(attendeeInfo: Array<AttendeeInfo>) {
        attendeeInfo.forEach {
            chimeFlutterApi.onAttendeeDropped(AttendeeMsg(it.attendeeId, it.externalUserId)) {}
        }
    }

    override fun onAttendeesMuted(attendeeInfo: Array<AttendeeInfo>) {
        attendeeInfo.forEach {
            chimeFlutterApi.onAttendeeMuted(AttendeeMsg(it.attendeeId, it.externalUserId)) {}
        }
    }

    override fun onAttendeesUnmuted(attendeeInfo: Array<AttendeeInfo>) {
        attendeeInfo.forEach {
            chimeFlutterApi.onAttendeeUnmuted(AttendeeMsg(it.attendeeId, it.externalUserId)) {}
        }
    }
}