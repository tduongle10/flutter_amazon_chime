/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Int?
        return VideoTileView(context, creationParams)
    }
}