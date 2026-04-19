import 'package:flutter_amazon_chime/models/video_tile_info.dart';

/// Represents a participant in an Amazon Chime meeting.
class Attendee {
  final String attendeeId;
  final String externalUserId;
  final bool muteStatus;
  final bool isVideoOn;
  final VideoTileInfo? videoTileInfo;

  const Attendee({
    required this.attendeeId,
    required this.externalUserId,
    this.muteStatus = false,
    this.isVideoOn = false,
    this.videoTileInfo,
  });

  factory Attendee.fromJson(dynamic jsonMap) {
    if (jsonMap == null) {
      throw const FormatException('Attendee JSON is null');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(jsonMap as Map);
    
    if (json['attendeeId'] == null || json['externalUserId'] == null) {
      throw FormatException('Attendee JSON missing required fields', json);
    }
    return Attendee(
      attendeeId: json['attendeeId'] as String,
      externalUserId: json['externalUserId'] as String,
    );
  }

  Attendee copyWith({
    String? attendeeId,
    String? externalUserId,
    bool? muteStatus,
    bool? isVideoOn,
    VideoTileInfo? videoTileInfo,
  }) {
    return Attendee(
      attendeeId: attendeeId ?? this.attendeeId,
      externalUserId: externalUserId ?? this.externalUserId,
      muteStatus: muteStatus ?? this.muteStatus,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      videoTileInfo: videoTileInfo ?? this.videoTileInfo,
    );
  }

  Attendee removeVideoTile() {
    return Attendee(
      attendeeId: attendeeId,
      externalUserId: externalUserId,
      muteStatus: muteStatus,
      isVideoOn: false,
      videoTileInfo: null,
    );
  }

  /// The human-readable portion of [externalUserId].
  ///
  /// Chime's convention is `"appId#username"` — this returns the username part.
  /// Falls back to the full [externalUserId] if the convention isn't followed.
  String get formattedExternalId {
    final parts = externalUserId.split('#');
    return parts.length == 2 ? parts[1] : externalUserId;
  }

  /// Whether this attendee represents a content share (screen share) source.
  ///
  /// Chime SDK appends `"#content"` to the base attendee ID for content sources,
  /// e.g. `"abc123#content"`.
  bool get isContent => attendeeId.endsWith('#content');

  /// Whether the given [attendeeId] string represents a content share source.
  static bool isContentId(String? attendeeId) {
    if (attendeeId == null) return false;
    return attendeeId.endsWith('#content');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendee &&
        other.attendeeId == attendeeId &&
        other.externalUserId == externalUserId &&
        other.muteStatus == muteStatus &&
        other.isVideoOn == isVideoOn &&
        other.videoTileInfo == videoTileInfo;
  }

  @override
  int get hashCode {
    return attendeeId.hashCode ^
        externalUserId.hashCode ^
        muteStatus.hashCode ^
        isVideoOn.hashCode ^
        (videoTileInfo?.hashCode ?? 0);
  }

  @override
  String toString() {
    return 'Attendee(attendeeId: $attendeeId, external: $externalUserId, mute: $muteStatus, video: $isVideoOn, tile: $videoTileInfo)';
  }
}
