/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */

package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.audiovideo.metric.MetricsObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.metric.ObservableMetric

class ChimeMetricsObserver(private val chimeFlutterApi: ChimeFlutterApi) : MetricsObserver {
    override fun onMetricsReceived(metrics: Map<ObservableMetric, Any>) {
        val stringMetrics: Map<String?, Any?> = metrics.entries.associate { (key, value) -> key.name to value }
        chimeFlutterApi.onMeetingMetricsReceived(stringMetrics) {}
    }
}
