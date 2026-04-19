import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/chime_api.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/retozu/flutter_amazon_chime/ChimeApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.retozu.flutter_amazon_chime'),
  swiftOut: 'ios/Classes/ChimeApi.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'flutter_amazon_chime',
))

class JoinInfoMsg {
  String? meetingId;
  String? externalMeetingId;
  String? mediaRegion;
  String? audioHostUrl;
  String? audioFallbackUrl;
  String? signalingUrl;
  String? turnControlUrl;
  String? externalUserId;
  String? attendeeId;
  String? joinToken;
  /// iOS only: the App Group ID shared between the main app and the
  /// ScreenShareExt broadcast extension (e.g. "group.com.example.app.screenshare").
  /// Required on iOS for screen share to work. Ignored on Android.
  String? appGroupId;

  /// iOS only: the full bundle identifier of the broadcast upload extension
  /// target (e.g. "com.example.app.ScreenShareExt"). Overrides the default
  /// discovery order, which is: this field, then the `ChimeScreenShareExtension`
  /// Info.plist key in the main app, then the fallback `<mainBundleId>.ScreenShareExt`.
  /// Ignored on Android.
  String? screenShareExtensionId;
}

class AttendeeMsg {
  String? attendeeId;
  String? externalUserId;
}

/// Carries a single attendee's volume level update.
/// [volume]: 0=muted, 1=notSpeaking, 2=low, 3=medium, 4=high
class AttendeeVolumeMsg {
  String? attendeeId;
  String? externalUserId;
  int? volume;
}

/// Carries a single attendee's signal strength update.
/// [signalStrength]: 0=none, 1=low, 2=high
class AttendeeSignalMsg {
  String? attendeeId;
  String? externalUserId;
  int? signalStrength;
}

/// A real-time data message sent between attendees.
class DataMessageMsg {
  /// The topic/channel this message was sent on.
  String? topic;
  /// The UTF-8 string payload.
  String? data;
  String? senderAttendeeId;
  String? senderExternalUserId;
  /// Server timestamp in milliseconds since epoch.
  int? timestampMs;
  /// True if the message was throttled by the server.
  bool? throttled;
}

class VideoTileMsg {
  int? tileId;
  String? attendeeId;
  int? videoStreamContentHeight;
  int? videoStreamContentWidth;
  bool? isLocalTile;
  bool? isDisplayOn;
}

/// Identifies a remote attendee's video source.
class RemoteVideoSourceMsg {
  String? attendeeId;
}

/// Defines operations called from Dart to Native.
@HostApi()
abstract class ChimeHostApi {
  @async
  bool manageAudioPermissions();
  @async
  bool manageVideoPermissions();
  /// Returns true if audio (microphone) permissions are already granted
  /// without showing a dialog. Use before [manageAudioPermissions] to check
  /// whether a rationale UI is needed.
  bool hasAudioPermissions();
  /// Returns true if video (camera) permissions are already granted
  /// without showing a dialog. Use before [manageVideoPermissions] to check
  /// whether a rationale UI is needed.
  bool hasVideoPermissions();
  void joinMeeting(JoinInfoMsg joinInfo);
  void stopMeeting();
  bool mute();
  bool unmute();
  void startLocalVideo();
  void stopLocalVideo();
  void startScreenShare();
  void stopScreenShare();
  /// Sends a real-time data message to all attendees on [topic].
  /// [lifetimeMs]: how long the message is retained for late joiners (0–300000).
  void sendDataMessage(String topic, String data, int lifetimeMs);
  /// Switches between front and back camera.
  void switchCamera();
  /// Returns the currently active camera facing: "front", "back", or null if unavailable.
  String? activeCamera();
  /// Sets the maximum encode bitrate (kbps) for the local video stream.
  /// Pass 0 to use the SDK default. Takes effect immediately if local video is active.
  void setLocalVideoMaxBitrate(int maxBitrateKbps);
  /// Subscribes to the given video sources and unsubscribes from the removed ones.
  void updateVideoSourceSubscriptions(List<RemoteVideoSourceMsg?> toAdd, List<RemoteVideoSourceMsg?> toRemove);
  String? initialAudioSelection();
  List<String?> listAudioDevices();
  bool updateAudioDevice(String deviceName);
}

/// Defines operations called from Native to Dart.
@FlutterApi()
abstract class ChimeFlutterApi {
  void onAttendeeJoined(AttendeeMsg attendee);
  void onAttendeeLeft(AttendeeMsg attendee);
  void onAttendeeDropped(AttendeeMsg attendee);
  void onAttendeeMuted(AttendeeMsg attendee);
  void onAttendeeUnmuted(AttendeeMsg attendee);
  void onVideoTileAdded(VideoTileMsg tile);
  void onVideoTileRemoved(VideoTileMsg tile);
  void onAudioSessionStarted();
  void onAudioSessionStopped();

  // — Audio session lifecycle (previously empty stubs) —
  void onAudioSessionStartConnecting(bool reconnecting);
  void onAudioSessionDropped();
  void onAudioSessionCancelledReconnect();

  // — Connection quality —
  /// [isPoor]: true when connection became poor, false when it recovered.
  void onConnectionQualityChanged(bool isPoor);

  // — Active speaker detection —
  void onActiveSpeakersChanged(List<String?> attendeeIds);

  // — Video tile pause/resume —
  void onVideoTilePaused(VideoTileMsg tile);
  void onVideoTileResumed(VideoTileMsg tile);

  // — Content share state —
  /// [state]: 0=started, 1=stopped
  void onContentShareStateChanged(int state);

  // — Volume / signal strength (high-frequency, opt-in) —
  void onAttendeesVolumeChanged(List<AttendeeVolumeMsg> updates);
  void onAttendeesSignalChanged(List<AttendeeSignalMsg> updates);

  // — Data messages —
  void onDataMessageReceived(DataMessageMsg message);

  // — Remote video sources —
  void onRemoteVideoSourcesAvailable(List<RemoteVideoSourceMsg?> sources);
  void onRemoteVideoSourcesUnavailable(List<RemoteVideoSourceMsg?> sources);

  // — Meeting quality metrics —
  /// Periodic metrics: map of metric name → numeric value.
  void onMeetingMetricsReceived(Map<String?, Object?> metrics);
  /// Structured analytics event from the SDK (e.g. meetingStartSucceeded, meetingFailed).
  void onMeetingEventReceived(String name, Map<String?, Object?> attributes);
}
