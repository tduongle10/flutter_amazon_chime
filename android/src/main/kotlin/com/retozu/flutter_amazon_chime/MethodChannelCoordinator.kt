/*
 * Copyright (c) 2025 Duong Le. MIT License.
 */
 
package com.retozu.flutter_amazon_chime

import com.amazonaws.services.chime.sdk.meetings.device.MediaDeviceType
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.LocalVideoConfiguration
import com.amazonaws.services.chime.sdk.meetings.session.DefaultMeetingSession
import com.amazonaws.services.chime.sdk.meetings.session.MediaPlacement
import com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionConfiguration
import com.amazonaws.services.chime.sdk.meetings.session.CreateMeetingResponse
import com.amazonaws.services.chime.sdk.meetings.session.Meeting
import com.amazonaws.services.chime.sdk.meetings.session.CreateAttendeeResponse
import com.amazonaws.services.chime.sdk.meetings.session.Attendee
import com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger
import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import io.flutter.plugin.common.BinaryMessenger

class MethodChannelCoordinator(private val binaryMessenger: BinaryMessenger, val activity: Activity) : ChimeHostApi {
    val context: Context
    var permissionsManager: PermissionManager = PermissionManager(activity)
    val chimeFlutterApi: ChimeFlutterApi

    /** Stored max bitrate for local video (0 = SDK default). */
    private var localVideoMaxBitrateKbps: Int = 0

    private val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityDestroyed(act: Activity) {
            if (act == activity && MeetingSessionManager.meetingSession != null) {
                stopMeeting()
            }
        }
        override fun onActivityCreated(act: Activity, savedInstanceState: Bundle?) {}
        override fun onActivityStarted(act: Activity) {}
        override fun onActivityResumed(act: Activity) {}
        override fun onActivityPaused(act: Activity) {}
        override fun onActivityStopped(act: Activity) {}
        override fun onActivitySaveInstanceState(act: Activity, outState: Bundle) {}
    }

    init {
        context = activity.applicationContext
        chimeFlutterApi = ChimeFlutterApi(binaryMessenger)
        ChimeHostApi.setUp(binaryMessenger, this)
        activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    fun cleanup() {
        activity.application.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
        ChimeHostApi.setUp(binaryMessenger, null)
    }

    override fun manageAudioPermissions(callback: (Result<Boolean>) -> Unit) {
        permissionsManager.manageAudioPermissions(callback)
    }

    override fun manageVideoPermissions(callback: (Result<Boolean>) -> Unit) {
        permissionsManager.manageVideoPermissions(callback)
    }

    override fun hasAudioPermissions(): Boolean {
        return permissionsManager.hasPermissionsGranted(permissionsManager.AUDIO_PERMISSIONS)
    }

    override fun hasVideoPermissions(): Boolean {
        return permissionsManager.hasPermissionsGranted(permissionsManager.VIDEO_PERMISSIONS)
    }

    override fun joinMeeting(joinInfo: JoinInfoMsg) {
        val externalMeetingId = joinInfo.externalMeetingId ?: throw IllegalArgumentException("externalMeetingId is required")
        val audioFallbackUrl = joinInfo.audioFallbackUrl ?: throw IllegalArgumentException("audioFallbackUrl is required")
        val audioHostUrl = joinInfo.audioHostUrl ?: throw IllegalArgumentException("audioHostUrl is required")
        val signalingUrl = joinInfo.signalingUrl ?: throw IllegalArgumentException("signalingUrl is required")
        val turnControlUrl = joinInfo.turnControlUrl ?: throw IllegalArgumentException("turnControlUrl is required")
        val mediaRegion = joinInfo.mediaRegion ?: throw IllegalArgumentException("mediaRegion is required")
        val meetingId = joinInfo.meetingId ?: throw IllegalArgumentException("meetingId is required")
        val attendeeId = joinInfo.attendeeId ?: throw IllegalArgumentException("attendeeId is required")
        val externalUserId = joinInfo.externalUserId ?: throw IllegalArgumentException("externalUserId is required")
        val joinToken = joinInfo.joinToken ?: throw IllegalArgumentException("joinToken is required")

        val createMeetingResponse = CreateMeetingResponse(
            Meeting(
                externalMeetingId,
                MediaPlacement(audioFallbackUrl, audioHostUrl, signalingUrl, turnControlUrl),
                mediaRegion,
                meetingId
            )
        )
        val createAttendeeResponse =
            CreateAttendeeResponse(Attendee(attendeeId, externalUserId, joinToken))
        val meetingSessionConfiguration =
            MeetingSessionConfiguration(createMeetingResponse, createAttendeeResponse)

        val meetingSession =
            DefaultMeetingSession(meetingSessionConfiguration, ConsoleLogger(), context)

        MeetingSessionManager.meetingSession = meetingSession
        MeetingSessionManager.startMeeting(
            ChimeRealtimeObserver(chimeFlutterApi),
            ChimeVideoTileObserver(chimeFlutterApi),
            ChimeAudioVideoObserver(chimeFlutterApi),
            ChimeActiveSpeakerObserver(chimeFlutterApi),
            ChimeContentShareObserver(chimeFlutterApi),
            ChimeDataMessageObserver(chimeFlutterApi),
            ChimeMetricsObserver(chimeFlutterApi),
            ChimeEventAnalyticsObserver(chimeFlutterApi)
        )
    }

    override fun stopMeeting() {
        // Clean up screen share resources before tearing down the session,
        // in case the user stops the meeting while screen sharing is active.
        if (screenCaptureSource != null) {
            MeetingSessionManager.meetingSession?.audioVideo?.stopContentShare()
            screenCaptureSource?.stop()
            screenCaptureSource = null
            val serviceIntent = android.content.Intent(context, ScreenShareService::class.java)
            context.stopService(serviceIntent)
        }
        MeetingSessionManager.stop()
    }

    override fun mute(): Boolean {
        return MeetingSessionManager.meetingSession?.audioVideo?.realtimeLocalMute() ?: false
    }

    override fun unmute(): Boolean {
        return MeetingSessionManager.meetingSession?.audioVideo?.realtimeLocalUnmute() ?: false
    }

    override fun startLocalVideo() {
        if (localVideoMaxBitrateKbps > 0) {
            MeetingSessionManager.meetingSession?.audioVideo?.startLocalVideo(
                LocalVideoConfiguration(maxBitRateKbps = localVideoMaxBitrateKbps)
            )
        } else {
            MeetingSessionManager.meetingSession?.audioVideo?.startLocalVideo()
        }
    }

    override fun switchCamera() {
        MeetingSessionManager.meetingSession?.audioVideo?.switchCamera()
    }

    override fun activeCamera(): String? {
        val device = MeetingSessionManager.meetingSession?.audioVideo?.getActiveCamera()
            ?: return null
        return when (device.type) {
            MediaDeviceType.VIDEO_FRONT_CAMERA -> "front"
            MediaDeviceType.VIDEO_BACK_CAMERA -> "back"
            else -> device.label
        }
    }

    override fun setLocalVideoMaxBitrate(maxBitrateKbps: Long) {
        localVideoMaxBitrateKbps = maxBitrateKbps.toInt()
        // If local video is active, restart it with the new config.
        MeetingSessionManager.meetingSession?.audioVideo?.startLocalVideo(
            LocalVideoConfiguration(maxBitRateKbps = localVideoMaxBitrateKbps)
        )
    }

    override fun stopLocalVideo() {
        MeetingSessionManager.meetingSession?.audioVideo?.stopLocalVideo()
    }

    override fun initialAudioSelection(): String? {
        return MeetingSessionManager.meetingSession?.audioVideo?.getActiveAudioDevice()?.label
    }

    override fun listAudioDevices(): List<String> {
        val audioDevices = MeetingSessionManager.meetingSession?.audioVideo?.listAudioDevices() ?: return emptyList()
        return audioDevices.map { it.label }
    }

    override fun updateAudioDevice(deviceName: String): Boolean {
        val audioDevices = MeetingSessionManager.meetingSession?.audioVideo?.listAudioDevices() ?: return false
        for (dev in audioDevices) {
            if (deviceName == dev.label) {
                MeetingSessionManager.meetingSession?.audioVideo?.chooseAudioDevice(dev)
                return true
            }
        }
        return false
    }

    var screenCaptureSource: com.amazonaws.services.chime.sdk.meetings.audiovideo.video.capture.DefaultScreenCaptureSource? = null

    override fun startScreenShare() {
        // On Android 13+ the foreground service requires a visible notification, which needs
        // POST_NOTIFICATIONS. Request it first; on older versions this is a no-op.
        permissionsManager.manageNotificationPermissions { _ ->
            launchMediaProjection()
        }
    }

    private fun launchMediaProjection() {
        MediaProjectionPermissionActivity.onPermissionResult = { resultCode, data ->
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Start persistent foreground service
                val serviceIntent = android.content.Intent(context, ScreenShareService::class.java)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }

                val factory = com.amazonaws.services.chime.sdk.meetings.audiovideo.video.gl.DefaultEglCoreFactory()
                
                screenCaptureSource = com.amazonaws.services.chime.sdk.meetings.audiovideo.video.capture.DefaultScreenCaptureSource(
                    context,
                    com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger(com.amazonaws.services.chime.sdk.meetings.utils.logger.LogLevel.INFO),
                    com.amazonaws.services.chime.sdk.meetings.audiovideo.video.capture.DefaultSurfaceTextureCaptureSourceFactory(
                        com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger(com.amazonaws.services.chime.sdk.meetings.utils.logger.LogLevel.INFO),
                        factory
                    ),
                    resultCode,
                    data
                )

                val contentShareSource = com.amazonaws.services.chime.sdk.meetings.audiovideo.contentshare.ContentShareSource()
                contentShareSource.videoSource = screenCaptureSource

                screenCaptureSource?.start()
                MeetingSessionManager.meetingSession?.audioVideo?.startContentShare(contentShareSource)
            }
        }

        val intent = android.content.Intent(context, MediaProjectionPermissionActivity::class.java)
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    override fun sendDataMessage(topic: String, data: String, lifetimeMs: Long) {
        val dataBytes = data.toByteArray(Charsets.UTF_8)
        MeetingSessionManager.meetingSession?.audioVideo?.realtimeSendDataMessage(topic, dataBytes, lifetimeMs.toInt())
    }

    override fun stopScreenShare() {
        MeetingSessionManager.meetingSession?.audioVideo?.stopContentShare()
        screenCaptureSource?.stop()
        screenCaptureSource = null

        val serviceIntent = android.content.Intent(context, ScreenShareService::class.java)
        context.stopService(serviceIntent)
    }

    override fun updateVideoSourceSubscriptions(toAdd: List<RemoteVideoSourceMsg?>, toRemove: List<RemoteVideoSourceMsg?>) {
        val addedOrUpdated = toAdd.filterNotNull().associate { msg ->
            com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource(msg.attendeeId ?: "") to
                com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoSubscriptionConfiguration(
                    priority = com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoPriority.High,
                    targetResolution = com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoResolution.High
                )
        }
        val removed = toRemove.filterNotNull().map { msg ->
            com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource(msg.attendeeId ?: "")
        }.toTypedArray()
        MeetingSessionManager.meetingSession?.audioVideo?.updateVideoSourceSubscriptions(addedOrUpdated, removed)
    }
}
