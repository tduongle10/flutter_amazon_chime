package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.realtime.datamessage.DataMessage
import com.amazonaws.services.chime.sdk.meetings.realtime.datamessage.DataMessageObserver

class ChimeDataMessageObserver(private val chimeFlutterApi: ChimeFlutterApi) : DataMessageObserver {
    /** The wildcard topic used to receive all data messages. */
    val topic = "*"

    override fun onDataMessageReceived(dataMessage: DataMessage) {
        val text = dataMessage.text() ?: ""
        val msg = DataMessageMsg(
            topic = dataMessage.topic,
            data = text,
            senderAttendeeId = dataMessage.senderAttendeeId,
            senderExternalUserId = dataMessage.senderExternalUserId,
            timestampMs = dataMessage.timestampMs,
            throttled = dataMessage.throttled
        )
        chimeFlutterApi.onDataMessageReceived(msg) {}
    }
}
