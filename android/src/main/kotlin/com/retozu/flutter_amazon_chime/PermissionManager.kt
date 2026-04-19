/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class PermissionManager(
    val activity: Activity
) {
    val context: Context = activity.applicationContext

    val VIDEO_PERMISSION_REQUEST_CODE = 1
    val VIDEO_PERMISSIONS = arrayOf(
        Manifest.permission.CAMERA
    )

    val AUDIO_PERMISSION_REQUEST_CODE = 2
    // BLUETOOTH_CONNECT is required on API 31+ to discover and connect to Bluetooth audio devices.
    val AUDIO_PERMISSIONS: Array<String> get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        arrayOf(
            Manifest.permission.MODIFY_AUDIO_SETTINGS,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.BLUETOOTH_CONNECT,
        )
    } else {
        arrayOf(
            Manifest.permission.MODIFY_AUDIO_SETTINGS,
            Manifest.permission.RECORD_AUDIO,
        )
    }

    val NOTIFICATION_PERMISSION_REQUEST_CODE = 3
    // POST_NOTIFICATIONS is required on API 33+ to show the foreground service notification
    // needed for screen share.
    val NOTIFICATION_PERMISSIONS: Array<String> get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        arrayOf(Manifest.permission.POST_NOTIFICATIONS)
    } else {
        emptyArray()
    }

    var audioResult: ((Result<Boolean>) -> Unit)? = null
    var videoResult: ((Result<Boolean>) -> Unit)? = null
    var notificationResult: ((Result<Boolean>) -> Unit)? = null

    fun manageNotificationPermissions(callback: (Result<Boolean>) -> Unit) {
        if (NOTIFICATION_PERMISSIONS.isEmpty()) {
            // Pre-API 33: no permission needed, grant immediately.
            callback(Result.success(true))
            return
        }
        notificationResult = callback
        if (hasPermissionsGranted(NOTIFICATION_PERMISSIONS)) {
            callback(Result.success(true))
            notificationResult = null
        } else {
            ActivityCompat.requestPermissions(
                activity,
                NOTIFICATION_PERMISSIONS,
                NOTIFICATION_PERMISSION_REQUEST_CODE
            )
        }
    }

    fun notificationCallbackReceived() {
        val callback = notificationResult ?: return
        notificationResult = null
        if (NOTIFICATION_PERMISSIONS.isEmpty() || hasPermissionsGranted(NOTIFICATION_PERMISSIONS)) {
            callback(Result.success(true))
        } else {
            callback(Result.failure(Exception("Notification permission denied")))
        }
    }

    fun manageAudioPermissions(callback: (Result<Boolean>) -> Unit) {
        audioResult = callback
        if (hasPermissionsGranted(AUDIO_PERMISSIONS)) {
            callback(Result.success(true))
            audioResult = null
        } else {
            ActivityCompat.requestPermissions(
                activity,
                AUDIO_PERMISSIONS,
                AUDIO_PERMISSION_REQUEST_CODE
            )
        }
    }

    fun manageVideoPermissions(callback: (Result<Boolean>) -> Unit) {
        videoResult = callback
        if (hasPermissionsGranted(VIDEO_PERMISSIONS)) {
            callback(Result.success(true))
            videoResult = null
        } else {
            ActivityCompat.requestPermissions(
                activity,
                VIDEO_PERMISSIONS,
                VIDEO_PERMISSION_REQUEST_CODE
            )
        }
    }

    fun audioCallbackReceived() {
        // Capture and clear before invoking to guard against re-entrant double-invocation.
        val callback = audioResult ?: return
        audioResult = null
        if (hasPermissionsGranted(AUDIO_PERMISSIONS)) {
            callback(Result.success(true))
        } else {
            callback(Result.failure(Exception("Permission denied")))
        }
    }

    fun videoCallbackReceived() {
        // Capture and clear before invoking to guard against re-entrant double-invocation.
        val callback = videoResult ?: return
        videoResult = null
        if (hasPermissionsGranted(VIDEO_PERMISSIONS)) {
            callback(Result.success(true))
        } else {
            callback(Result.failure(Exception("Permission denied")))
        }
    }

    fun hasPermissionsGranted(permissions: Array<String>): Boolean {
        return permissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }
}