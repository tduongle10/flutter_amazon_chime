import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_amazon_chime/models/models.dart';
import 'package:flutter_amazon_chime/method_channel_coordinator.dart';
import 'package:flutter_amazon_chime/src/chime_api.dart';

/// The core Amazon Chime SDK interface. 
/// Use [AmazonChime.instance] to access the SDK methods.
class AmazonChime {
  AmazonChime._();
  
  /// The singleton instance of the AmazonChime SDK wrapper.
  static final AmazonChime instance = AmazonChime._();

  final MethodChannelCoordinator _coordinator = MethodChannelCoordinator.instance;

  /// Stream of attendees joining the meeting.
  Stream<Attendee> get onAttendeeJoined => _coordinator.attendeeJoinedStream;

  /// Stream of attendees leaving the meeting.
  Stream<Attendee> get onAttendeeLeft => _coordinator.attendeeLeftStream;

  /// Stream of attendees dropping from the meeting.
  Stream<Attendee> get onAttendeeDropped => _coordinator.attendeeDroppedStream;

  /// Stream of attendees being muted.
  Stream<Attendee> get onAttendeeMuted => _coordinator.attendeeMutedStream;

  /// Stream of attendees being unmuted.
  Stream<Attendee> get onAttendeeUnmuted => _coordinator.attendeeUnmutedStream;

  /// Stream of video tiles being added.
  Stream<VideoTileInfo> get onVideoTileAdded => _coordinator.videoTileAddedStream;

  /// Stream of video tiles being removed.
  Stream<VideoTileInfo> get onVideoTileRemoved => _coordinator.videoTileRemovedStream;

  /// Stream emitting when the audio session has started (or successfully reconnected).
  Stream<void> get onAudioSessionStarted => _coordinator.audioSessionStartedStream;

  /// Stream emitting when the audio session stops.
  Stream<void> get onAudioSessionStopped => _coordinator.audioSessionStoppedStream;

  /// Stream emitting when the audio session starts connecting.
  /// The emitted bool is `true` when this is a reconnect attempt, `false` for
  /// the initial connection.
  Stream<bool> get onAudioSessionStartConnecting => _coordinator.audioSessionStartConnectingStream;

  /// Stream emitting when the audio session is dropped.
  Stream<void> get onAudioSessionDropped => _coordinator.audioSessionDroppedStream;

  /// Stream emitting when a reconnect attempt is cancelled.
  Stream<void> get onAudioSessionCancelledReconnect => _coordinator.audioSessionCancelledReconnectStream;

  /// Stream emitting connection quality changes.
  /// `true` = connection became poor, `false` = connection recovered.
  Stream<bool> get onConnectionQualityChanged => _coordinator.connectionQualityChangedStream;

  /// Stream emitting the current list of active speaker attendee IDs.
  Stream<List<String>> get onActiveSpeakersChanged => _coordinator.activeSpeakersChangedStream;

  /// Stream emitting when a video tile is paused.
  Stream<VideoTileInfo> get onVideoTilePaused => _coordinator.videoTilePausedStream;

  /// Stream emitting when a video tile is resumed.
  Stream<VideoTileInfo> get onVideoTileResumed => _coordinator.videoTileResumedStream;

  /// Stream emitting content share state changes.
  /// `0` = started, `1` = stopped.
  Stream<int> get onContentShareStateChanged => _coordinator.contentShareStateChangedStream;

  /// Stream emitting batched volume level updates for attendees.
  Stream<List<AttendeeVolume>> get onAttendeesVolumeChanged => _coordinator.attendeesVolumeChangedStream;

  /// Stream emitting batched signal strength updates for attendees.
  Stream<List<AttendeeSignal>> get onAttendeesSignalChanged => _coordinator.attendeesSignalChangedStream;

  /// Stream emitting data messages received from other attendees.
  Stream<DataMessage> get onDataMessageReceived => _coordinator.dataMessageReceivedStream;

  /// Stream emitting when remote video sources become available.
  Stream<List<RemoteVideoSource>> get onRemoteVideoSourcesAvailable => _coordinator.remoteVideoSourcesAvailableStream;

  /// Stream emitting when remote video sources become unavailable.
  Stream<List<RemoteVideoSource>> get onRemoteVideoSourcesUnavailable => _coordinator.remoteVideoSourcesUnavailableStream;

  /// Stream emitting periodic meeting quality metrics.
  /// Keys are metric names (e.g. "audioPacketsReceivedFractionLoss"), values are numeric.
  Stream<Map<String, Object?>> get onMeetingMetricsReceived => _coordinator.meetingMetricsReceivedStream;

  /// Stream emitting structured SDK analytics events.
  /// See [MeetingEvent] for the event name and attribute map.
  Stream<MeetingEvent> get onMeetingEventReceived => _coordinator.meetingEventReceivedStream;

  /// Sends a real-time data message to all attendees subscribed to [topic].
  ///
  /// [lifetimeMs]: how long the message is retained for late joiners (0–300 000 ms).
  /// Throws [ChimeMeetingException] if the session is not active.
  Future<void> sendDataMessage(String topic, String data, {int lifetimeMs = 0}) async {
    try {
      await _coordinator.hostApi.sendDataMessage(topic, data, lifetimeMs);
    } on PlatformException catch (e) {
      throw ChimeMeetingException('Failed to send data message', e.message);
    }
  }

  /// Returns `true` if microphone permissions are already granted, without showing a dialog.
  /// Use this to decide whether to show a custom rationale UI before calling [requestAudioPermissions].
  Future<bool> hasAudioPermissions() async {
    try {
      return await _coordinator.hostApi.hasAudioPermissions();
    } on PlatformException catch (e) {
      throw ChimePermissionException('Failed to check audio permissions', e.message);
    }
  }

  /// Returns `true` if camera permissions are already granted, without showing a dialog.
  /// Use this to decide whether to show a custom rationale UI before calling [requestVideoPermissions].
  Future<bool> hasVideoPermissions() async {
    try {
      return await _coordinator.hostApi.hasVideoPermissions();
    } on PlatformException catch (e) {
      throw ChimePermissionException('Failed to check video permissions', e.message);
    }
  }

  /// Requests audio permissions. Throws [ChimePermissionException] if denied.
  Future<void> requestAudioPermissions() async {
    try {
      final granted = await _coordinator.hostApi.manageAudioPermissions();
      if (!granted) {
        throw ChimePermissionException('Audio permissions denied', '');
      }
    } on PlatformException catch (e) {
      throw ChimePermissionException('Audio permissions denied', e.message);
    }
  }

  /// Requests video permissions. Throws [ChimePermissionException] if denied.
  Future<void> requestVideoPermissions() async {
    try {
      final granted = await _coordinator.hostApi.manageVideoPermissions();
      if (!granted) {
        throw ChimePermissionException('Video permissions denied', '');
      }
    } on PlatformException catch (e) {
      throw ChimePermissionException('Video permissions denied', e.message);
    }
  }

  /// Joins a meeting using the provided [JoinInfo].
  Future<void> joinMeeting(JoinInfo info) async {
    try {
      final joinInfoMsg = JoinInfoMsg(
        meetingId: info.meetingId,
        externalMeetingId: info.externalMeetingId,
        mediaRegion: info.mediaRegion,
        audioHostUrl: info.audioHostUrl,
        audioFallbackUrl: info.audioFallbackUrl,
        signalingUrl: info.signalingUrl,
        turnControlUrl: info.turnControlUrl,
        externalUserId: info.externalUserId,
        attendeeId: info.attendeeId,
        joinToken: info.joinToken,
        appGroupId: info.appGroupId,
        screenShareExtensionId: info.screenShareExtensionId,
      );
      await _coordinator.hostApi.joinMeeting(joinInfoMsg);
    } on PlatformException catch (e) {
      throw ChimeMeetingException('Failed to join meeting', e.message);
    }
  }

  /// Stops the current meeting session.
  Future<void> stopMeeting() async {
    try {
      await _coordinator.hostApi.stopMeeting();
    } on PlatformException catch (e) {
      throw ChimeMeetingException('Failed to stop meeting', e.message);
    }
  }

  /// Mutes the local attendee.
  Future<void> mute() async {
    try {
      final success = await _coordinator.hostApi.mute();
      if (!success) throw ChimeDeviceException('Failed to mute', 'Mute returned false');
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to mute', e.message);
    }
  }

  /// Unmutes the local attendee.
  Future<void> unmute() async {
    try {
      final success = await _coordinator.hostApi.unmute();
      if (!success) throw ChimeDeviceException('Failed to unmute', 'Unmute returned false');
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to unmute', e.message);
    }
  }

  /// Starts the local video.
  Future<void> startLocalVideo() async {
    try {
      await _coordinator.hostApi.startLocalVideo();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to start local video', e.message);
    }
  }

  /// Stops the local video.
  Future<void> stopLocalVideo() async {
    try {
      await _coordinator.hostApi.stopLocalVideo();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to stop local video', e.message);
    }
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    try {
      await _coordinator.hostApi.switchCamera();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to switch camera', e.message);
    }
  }

  /// Returns the currently active camera facing: `"front"`, `"back"`, or `null`.
  Future<String?> activeCamera() async {
    try {
      return await _coordinator.hostApi.activeCamera();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to get active camera', e.message);
    }
  }

  /// Sets the maximum encode bitrate (kbps) for the local video stream.
  ///
  /// Pass `0` to restore the SDK default. Takes effect immediately if local
  /// video is already active.
  Future<void> setLocalVideoMaxBitrate(int maxBitrateKbps) async {
    try {
      await _coordinator.hostApi.setLocalVideoMaxBitrate(maxBitrateKbps);
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to set video bitrate', e.message);
    }
  }

  /// Starts sharing the foreground screen to the meeting.
  Future<void> startScreenShare() async {
    try {
      await _coordinator.hostApi.startScreenShare();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to start screen share', e.message);
    }
  }

  /// Subscribes to the specified remote video sources and unsubscribes from the removed ones.
  ///
  /// Call this in response to [onRemoteVideoSourcesAvailable] to receive video from remote attendees.
  /// Pass an attendee's source in [toRemove] to stop receiving their video.
  Future<void> updateVideoSourceSubscriptions({
    required List<RemoteVideoSource> toAdd,
    List<RemoteVideoSource> toRemove = const [],
  }) async {
    try {
      await _coordinator.hostApi.updateVideoSourceSubscriptions(
        toAdd.map((s) => RemoteVideoSourceMsg(attendeeId: s.attendeeId)).toList(),
        toRemove.map((s) => RemoteVideoSourceMsg(attendeeId: s.attendeeId)).toList(),
      );
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to update video source subscriptions', e.message);
    }
  }

  /// Stops sharing the screen.
  Future<void> stopScreenShare() async {
    try {
      await _coordinator.hostApi.stopScreenShare();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to stop screen share', e.message);
    }
  }

  /// Retrieves the initial audio device selection.
  Future<String> initialAudioSelection() async {
    try {
      final device = await _coordinator.hostApi.initialAudioSelection();
      if (device == null) throw ChimeDeviceException('Failed to get initial audio device', 'No active audio device');
      return device;
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to get initial audio device', e.message);
    }
  }

  /// Lists all available audio devices.
  Future<List<String>> listAudioDevices() async {
    try {
      final devices = await _coordinator.hostApi.listAudioDevices();
      return devices.whereType<String>().toList();
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to list audio devices', e.message);
    }
  }

  /// Updates the audio device to the specified [device].
  Future<void> updateAudioDevice(String device) async {
    try {
      final success = await _coordinator.hostApi.updateAudioDevice(device);
      if (!success) throw ChimeDeviceException('Failed to update audio device', 'Device "$device" not found');
    } on PlatformException catch (e) {
      throw ChimeDeviceException('Failed to update audio device', e.message);
    }
  }
}
