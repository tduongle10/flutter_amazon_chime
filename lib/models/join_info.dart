/// Contains all the necessary data to join an Amazon Chime SDK meeting.
/// Usually obtained from your server-side application.
class JoinInfo {
  final String meetingId;
  final String externalMeetingId;
  final String mediaRegion;
  final String audioHostUrl;
  final String audioFallbackUrl;
  final String signalingUrl;
  final String turnControlUrl;
  final String externalUserId;
  final String attendeeId;
  final String joinToken;
  /// iOS only: the App Group ID shared between the main app target and the
  /// ScreenShareExt broadcast extension, as configured in Xcode Signing &
  /// Capabilities (e.g. "group.com.example.app.screenshare").
  /// Required on iOS when using screen share. Ignored on Android.
  final String? appGroupId;

  /// iOS only: full bundle identifier of the broadcast upload extension
  /// (e.g. "com.example.app.ScreenShareExt"). When set, overrides the default
  /// discovery order: this field, then the `ChimeScreenShareExtension` key in
  /// the main app's Info.plist, then the fallback `<mainBundleId>.ScreenShareExt`.
  /// Ignored on Android.
  final String? screenShareExtensionId;

  const JoinInfo({
    required this.meetingId,
    required this.externalMeetingId,
    required this.mediaRegion,
    required this.audioHostUrl,
    required this.audioFallbackUrl,
    required this.signalingUrl,
    required this.turnControlUrl,
    required this.externalUserId,
    required this.attendeeId,
    required this.joinToken,
    this.appGroupId,
    this.screenShareExtensionId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'MeetingId': meetingId,
      'ExternalMeetingId': externalMeetingId,
      'MediaRegion': mediaRegion,
      'AudioHostUrl': audioHostUrl,
      'AudioFallbackUrl': audioFallbackUrl,
      'SignalingUrl': signalingUrl,
      'TurnControlUrl': turnControlUrl,
      'ExternalUserId': externalUserId,
      'AttendeeId': attendeeId,
      'JoinToken': joinToken,
      if (appGroupId != null) 'AppGroupId': appGroupId,
      if (screenShareExtensionId != null)
        'ScreenShareExtensionId': screenShareExtensionId,
    };
  }

  factory JoinInfo.fromJson(Map<String, dynamic> json) {
    return JoinInfo(
      meetingId: json['MeetingId'] as String? ?? '',
      externalMeetingId: json['ExternalMeetingId'] as String? ?? '',
      mediaRegion: json['MediaRegion'] as String? ?? '',
      audioHostUrl: json['AudioHostUrl'] as String? ?? '',
      audioFallbackUrl: json['AudioFallbackUrl'] as String? ?? '',
      signalingUrl: json['SignalingUrl'] as String? ?? '',
      turnControlUrl: json['TurnControlUrl'] as String? ?? '',
      externalUserId: json['ExternalUserId'] as String? ?? '',
      attendeeId: json['AttendeeId'] as String? ?? '',
      joinToken: json['JoinToken'] as String? ?? '',
      appGroupId: json['AppGroupId'] as String?,
      screenShareExtensionId: json['ScreenShareExtensionId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JoinInfo &&
        other.meetingId == meetingId &&
        other.externalMeetingId == externalMeetingId &&
        other.mediaRegion == mediaRegion &&
        other.audioHostUrl == audioHostUrl &&
        other.audioFallbackUrl == audioFallbackUrl &&
        other.signalingUrl == signalingUrl &&
        other.turnControlUrl == turnControlUrl &&
        other.externalUserId == externalUserId &&
        other.attendeeId == attendeeId &&
        other.joinToken == joinToken &&
        other.appGroupId == appGroupId &&
        other.screenShareExtensionId == screenShareExtensionId;
  }

  @override
  int get hashCode {
    return Object.hash(
      meetingId,
      externalMeetingId,
      mediaRegion,
      audioHostUrl,
      audioFallbackUrl,
      signalingUrl,
      turnControlUrl,
      externalUserId,
      attendeeId,
      joinToken,
      appGroupId,
      screenShareExtensionId,
    );
  }

  @override
  String toString() => 'JoinInfo(meetingId: $meetingId, attendeeId: $attendeeId)';
}
