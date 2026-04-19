package com.retozu.flutter_amazon_chime

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry

/** FlutterAmazonChimePlugin */
class FlutterAmazonChimePlugin : FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private var methodChannel: MethodChannelCoordinator? = null
    private var messenger: BinaryMessenger? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        messenger = flutterPluginBinding.binaryMessenger
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "videoTile",
            NativeViewFactory()
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        messenger?.let { messenger ->
            methodChannel = MethodChannelCoordinator(messenger, binding.activity)
        }

        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        methodChannel?.cleanup()
        methodChannel = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        methodChannel?.cleanup()
        methodChannel = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        messenger?.let { messenger ->
            methodChannel = MethodChannelCoordinator(messenger, binding.activity)
        }

        binding.addRequestPermissionsResultListener(this) 
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = null
        messenger = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
        ): Boolean {
        val permissionsManager = methodChannel?.permissionsManager ?: return false
        return when (requestCode) {
            permissionsManager.AUDIO_PERMISSION_REQUEST_CODE -> {
               permissionsManager.audioCallbackReceived()
               true
            }
            permissionsManager.VIDEO_PERMISSION_REQUEST_CODE -> {
                permissionsManager.videoCallbackReceived()
                true
            }
            permissionsManager.NOTIFICATION_PERMISSION_REQUEST_CODE -> {
                permissionsManager.notificationCallbackReceived()
                true
            }
            else -> false
        }
    }
}
