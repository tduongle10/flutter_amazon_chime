/// Represents an active video stream tile from the Amazon Chime SDK.
class VideoTileInfo {
  final int tileId;
  final String attendeeId;
  final int videoStreamContentWidth;
  final int videoStreamContentHeight;
  final bool isLocalTile;
  final bool isContentShare;

  const VideoTileInfo({
    required this.tileId,
    required this.attendeeId,
    required this.videoStreamContentWidth,
    required this.videoStreamContentHeight,
    required this.isLocalTile,
    required this.isContentShare,
  });

  factory VideoTileInfo.fromJson(dynamic jsonMap) {
    if (jsonMap == null) {
      throw const FormatException('VideoTileInfo JSON is null');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(jsonMap as Map);

    final tileId = json['tileId'] as int?;
    final attendeeId = json['attendeeId'] as String?;
    if (tileId == null) throw FormatException('VideoTileInfo missing tileId', json);
    if (attendeeId == null || attendeeId.isEmpty) throw FormatException('VideoTileInfo missing attendeeId', json);

    return VideoTileInfo(
      tileId: tileId,
      attendeeId: attendeeId,
      videoStreamContentWidth: json['videoStreamContentWidth'] as int? ?? 0,
      videoStreamContentHeight: json['videoStreamContentHeight'] as int? ?? 0,
      isLocalTile: json['isLocalTile'] as bool? ?? false,
      isContentShare: json['isContentShare'] as bool? ?? false,
    );
  }

  VideoTileInfo copyWith({
    int? tileId,
    String? attendeeId,
    int? videoStreamContentWidth,
    int? videoStreamContentHeight,
    bool? isLocalTile,
    bool? isContentShare,
  }) {
    return VideoTileInfo(
      tileId: tileId ?? this.tileId,
      attendeeId: attendeeId ?? this.attendeeId,
      videoStreamContentWidth: videoStreamContentWidth ?? this.videoStreamContentWidth,
      videoStreamContentHeight: videoStreamContentHeight ?? this.videoStreamContentHeight,
      isLocalTile: isLocalTile ?? this.isLocalTile,
      isContentShare: isContentShare ?? this.isContentShare,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoTileInfo &&
        other.tileId == tileId &&
        other.attendeeId == attendeeId &&
        other.videoStreamContentWidth == videoStreamContentWidth &&
        other.videoStreamContentHeight == videoStreamContentHeight &&
        other.isLocalTile == isLocalTile &&
        other.isContentShare == isContentShare;
  }

  @override
  int get hashCode {
    return tileId.hashCode ^
        attendeeId.hashCode ^
        videoStreamContentWidth.hashCode ^
        videoStreamContentHeight.hashCode ^
        isLocalTile.hashCode ^
        isContentShare.hashCode;
  }

  @override
  String toString() {
    return 'VideoTileInfo(tileId: $tileId, attendeeId: $attendeeId, local: $isLocalTile, content: $isContentShare, ${videoStreamContentWidth}x$videoStreamContentHeight)';
  }
}
