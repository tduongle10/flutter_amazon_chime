package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.contentshare.ContentShareObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.contentshare.ContentShareStatus

class ChimeContentShareObserver(private val chimeFlutterApi: ChimeFlutterApi) : ContentShareObserver {
    override fun onContentShareStarted() {
        chimeFlutterApi.onContentShareStateChanged(0L) {}
    }

    override fun onContentShareStopped(status: ContentShareStatus) {
        chimeFlutterApi.onContentShareStateChanged(1L) {}
    }
}
