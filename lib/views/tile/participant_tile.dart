import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/models/models.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:flutter_amazon_chime/views/tile/video_tile.dart';

/// A composable tile that renders a participant's video (or avatar if video
/// is off), with optional name label and mic status overlay.
///
/// SDK users can use this standalone to build custom meeting layouts:
/// ```dart
/// ParticipantTile(
///   attendee: myAttendee,
///   displayName: 'John',
///   showNameLabel: true,
///   showMicIndicator: true,
///   borderRadius: BorderRadius.circular(8),
/// )
/// ```
class ParticipantTile extends StatelessWidget {
  /// The attendee to display.
  final Attendee attendee;

  /// Display name shown on the tile. If null, uses externalUserId initials.
  final String? displayName;

  /// Whether to show the name label at the bottom of the tile.
  final bool showNameLabel;

  /// Whether to show the mic status indicator.
  final bool showMicIndicator;

  /// Border radius for the tile. Defaults to 12px.
  final BorderRadius borderRadius;

  /// Background color when video is off. Defaults to dark gray.
  final Color backgroundColor;

  /// Avatar text style for initials when video is off.
  final TextStyle? avatarTextStyle;

  /// Size of the avatar circle when video is off. Defaults to 56.
  final double avatarSize;

  /// When true, a green border ring is drawn to indicate active speaking.
  final bool isActiveSpeaker;

  const ParticipantTile({
    super.key,
    required this.attendee,
    this.displayName,
    this.showNameLabel = true,
    this.showMicIndicator = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.backgroundColor = ChimeColors.surfaceVariant,
    this.avatarTextStyle,
    this.avatarSize = 56,
    this.isActiveSpeaker = false,
  });

  String get _name => displayName ?? attendee.formattedExternalId;

  String get _initials {
    final name = _name;
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get _hasVideo => attendee.isVideoOn && attendee.videoTileInfo != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: isActiveSpeaker
            ? Border.all(color: ChimeColors.activeSpeaker, width: 2.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: isActiveSpeaker
            ? BorderRadius.only(
                topLeft: Radius.circular(
                  (borderRadius.topLeft.x - 2.5).clamp(0, double.infinity),
                ),
                topRight: Radius.circular(
                  (borderRadius.topRight.x - 2.5).clamp(0, double.infinity),
                ),
                bottomLeft: Radius.circular(
                  (borderRadius.bottomLeft.x - 2.5).clamp(0, double.infinity),
                ),
                bottomRight: Radius.circular(
                  (borderRadius.bottomRight.x - 2.5).clamp(0, double.infinity),
                ),
              )
            : borderRadius,
        child: Container(
          color: backgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video or avatar
              if (_hasVideo)
                VideoTile(tileId: attendee.videoTileInfo!.tileId)
              else
                Center(
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: _avatarColor(_name),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style:
                            avatarTextStyle ??
                            TextStyle(
                              color: ChimeColors.surface,
                              fontSize: avatarSize * 0.4,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),

              // Bottom gradient + name label
              if (showNameLabel || showMicIndicator)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 6,
                      top: 12,
                    ),
                    child: Row(
                      children: [
                        if (showMicIndicator)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              attendee.muteStatus ? Icons.mic_off : Icons.mic,
                              color: ChimeColors.surface,
                              size: 16,
                            ),
                          ),
                        if (showNameLabel)
                          Expanded(
                            child: Text(
                              _name,
                              style: const TextStyle(
                                color: ChimeColors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deterministic color from a name string for consistent avatars.
  static Color _avatarColor(String name) {
    final index = name.hashCode.abs() % ChimeColors.avatarPalette.length;
    return ChimeColors.avatarPalette[index];
  }
}
