import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/models/models.dart';
import 'package:flutter_amazon_chime/views/tile/participant_tile.dart';
import 'package:flutter_amazon_chime/styles/style.dart';

/// An adaptive grid layout that arranges participant tiles like Google Meet.
///
/// - Max 6 visible tiles on screen (no scrolling).
/// - If participants > 6: shows 5 tiles + a "+N" overflow tile.
/// - Responsive layout adapts to participant count.
///
/// SDK users can use this standalone:
/// ```dart
/// ParticipantGrid(
///   participants: session.allParticipants,
///   localAttendeeId: session.localAttendeeId,
///   roster: session.roster,
///   maxVisibleTiles: 6,
/// )
/// ```
class ParticipantGrid extends StatelessWidget {
  /// All participants to render (including local).
  final List<Attendee> participants;

  /// The local attendee's ID — used to identify the local tile.
  final String? localAttendeeId;

  /// Optional roster map (attendeeId → display name).
  final Map<String, String> roster;

  /// Optional custom tile builder. If null, uses default [ParticipantTile].
  final Widget Function(BuildContext context, Attendee attendee, bool isLocal)?
  tileBuilder;

  /// Spacing between grid tiles. Defaults to 4.
  final double spacing;

  /// Border radius for default tiles. Ignored if [tileBuilder] is provided.
  final BorderRadius tileBorderRadius;

  /// Maximum number of visible tiles. Tiles beyond this show as "+N".
  /// Defaults to 6.
  final int maxVisibleTiles;

  /// Set of attendee IDs that are currently active speakers.
  /// Used to show a speaking ring on their tile.
  final Set<String> activeSpeakers;

  const ParticipantGrid({
    super.key,
    required this.participants,
    this.localAttendeeId,
    this.roster = const {},
    this.tileBuilder,
    this.spacing = 8,
    this.tileBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.maxVisibleTiles = 6,
    this.activeSpeakers = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for participants...',
          style: TextStyle(color: ChimeColors.surface, fontSize: 16),
        ),
      );
    }

    final count = participants.length;
    final hasOverflow = count > maxVisibleTiles;
    final visibleCount = hasOverflow ? maxVisibleTiles - 1 : count;
    final overflowCount = count - visibleCount;

    // Build list of tile widgets
    final tiles = <Widget>[];
    for (int i = 0; i < visibleCount; i++) {
      tiles.add(_buildTile(context, participants[i]));
    }
    if (hasOverflow) {
      tiles.add(_buildOverflowTile(overflowCount));
    }

    return _buildResponsiveGrid(tiles);
  }

  /// Builds a responsive grid layout based on the number of tiles.
  ///
  /// Layout patterns:
  /// - 1 tile: full screen
  /// - 2 tiles: 2 columns, 1 row
  /// - 3 tiles: top row (2), bottom row (1 centered)
  /// - 4 tiles: 2×2
  /// - 5 tiles: top row (3), bottom row (2)
  /// - 6 tiles: 3×2
  Widget _buildResponsiveGrid(List<Widget> tiles) {
    final count = tiles.length;

    if (count == 1) {
      return tiles.first;
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: tiles[0]),
          SizedBox(width: spacing),
          Expanded(child: tiles[1]),
        ],
      );
    }

    if (count == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tiles[0]),
                SizedBox(width: spacing),
                Expanded(child: tiles[1]),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Center(
              child: FractionallySizedBox(widthFactor: 0.5, child: tiles[2]),
            ),
          ),
        ],
      );
    }

    if (count == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tiles[0]),
                SizedBox(width: spacing),
                Expanded(child: tiles[1]),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(child: tiles[2]),
                SizedBox(width: spacing),
                Expanded(child: tiles[3]),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 5) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tiles[0]),
                SizedBox(width: spacing),
                Expanded(child: tiles[1]),
                SizedBox(width: spacing),
                Expanded(child: tiles[2]),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Expanded(flex: 2, child: tiles[3]),
                SizedBox(width: spacing),
                Expanded(flex: 2, child: tiles[4]),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      );
    }

    // 6 tiles: 3×2
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: tiles[0]),
              SizedBox(width: spacing),
              Expanded(child: tiles[1]),
              SizedBox(width: spacing),
              Expanded(child: tiles[2]),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: tiles[3]),
              SizedBox(width: spacing),
              Expanded(child: tiles[4]),
              SizedBox(width: spacing),
              Expanded(child: tiles[5]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, Attendee attendee) {
    final isLocal = attendee.attendeeId == localAttendeeId;

    if (tileBuilder != null) {
      return tileBuilder!(context, attendee, isLocal);
    }

    final name = isLocal
        ? 'You'
        : roster[attendee.attendeeId] ?? attendee.formattedExternalId;

    return ParticipantTile(
      attendee: attendee,
      displayName: name,
      borderRadius: tileBorderRadius,
      isActiveSpeaker:
          activeSpeakers.contains(attendee.attendeeId) && !attendee.muteStatus,
    );
  }

  Widget _buildOverflowTile(int overflowCount) {
    return ClipRRect(
      borderRadius: tileBorderRadius,
      child: Container(
        color: ChimeColors.surfaceVariant,
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ChimeColors.buttonBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+$overflowCount',
                style: const TextStyle(
                  color: ChimeColors.surface,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
