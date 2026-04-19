import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/models/attendee.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/meeting_controls.dart';
import 'package:flutter_amazon_chime/views/grid/participant_grid.dart';
import 'package:flutter_amazon_chime/views/tile/participant_tile.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:flutter_amazon_chime/views/tile/video_tile.dart';
import 'package:provider/provider.dart';

/// A full-screen meeting view with multi-participant grid, meeting controls, and
/// screen share support.
///
/// This is the "batteries included" widget — use it to get a complete meeting
/// UI out of the box. For custom layouts, use [ParticipantGrid],
/// [ParticipantTile], [VideoTile], and [MeetingControls] directly.
///
/// ```dart
/// // Out-of-the-box usage:
/// AmazonChimeView(title: 'My Meeting')
///
/// // Custom usage — build your own layout:
/// Scaffold(
///   body: Column(
///     children: [
///       Expanded(
///         child: ParticipantGrid(
///           participants: session.allParticipants,
///           localAttendeeId: session.localAttendeeId,
///           roster: session.roster,
///         ),
///       ),
///       MeetingControls(),
///     ],
///   ),
/// )
/// ```
class AmazonChimeView extends StatefulWidget {
  /// Optional title displayed in the app bar.
  final String? title;

  /// Called after the meeting is stopped and the view is popped.
  final VoidCallback? onLeave;

  /// Custom tile builder passed to [ParticipantGrid].
  /// If null, uses default [ParticipantTile].
  final Widget Function(BuildContext, Attendee, bool)? tileBuilder;

  const AmazonChimeView({
    this.title,
    this.onLeave,
    this.tileBuilder,
    super.key,
  });

  @override
  State<AmazonChimeView> createState() => _AmazonChimeViewState();
}

class _AmazonChimeViewState extends State<AmazonChimeView> {
  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          session.stopMeeting();
          widget.onLeave?.call();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ChimeColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildMainContent(session)),
                      // Connection quality banner
                      if (session.isConnectionPoor)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _ConnectionBanner(
                            message: 'Poor connection',
                            color: ChimeColors.connectionPoor,
                          ),
                        ),
                      // Reconnecting overlay
                      if (session.isReconnecting)
                        Positioned.fill(child: _ReconnectingOverlay()),
                    ],
                  ),
                ),
              ),

              // Meeting controls
              Padding(
                padding: const EdgeInsets.all(8),
                child: MeetingControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ChimeSession session) {
    // Local screen share takes ultimate priority (shows placeholder UI)
    if (session.isLocalScreenSharing) {
      return _buildLocalScreenShareLayout(session);
    }

    // Remote screen share takes priority
    if (session.shouldShowScreenShare) {
      return _buildScreenShareLayout(session);
    }

    // Participant grid handles all layouts: 1→full, 2→row, 3-6→grid, 7+→overflow
    return ParticipantGrid(
      participants: session.allParticipants,
      localAttendeeId: session.localAttendeeId,
      roster: session.roster,
      activeSpeakers: session.activeSpeakers.toSet(),
    );
  }

  /// Screen share layout for when YOU are sharing the screen.
  Widget _buildLocalScreenShareLayout(ChimeSession session) {
    return Column(
      children: [
        // Screen share placeholder
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: ChimeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.screen_share, size: 60, color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    'You are presenting your screen to everyone.',
                    style: TextStyle(
                      color: ChimeColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),
        _buildParticipantStrip(session),
      ],
    );
  }

  /// Screen share layout — content fullscreen + participants strip.
  Widget _buildScreenShareLayout(ChimeSession session) {
    final contentTileId = session
        .currAttendees[session.contentAttendeeId]
        ?.videoTileInfo
        ?.tileId;

    return Column(
      children: [
        // Screen share content
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(child: VideoTile(tileId: contentTileId)),
          ),
        ),

        const SizedBox(height: 4),
        _buildParticipantStrip(session),
      ],
    );
  }

  Widget _buildParticipantStrip(ChimeSession session) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: session.allParticipants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final attendee = session.allParticipants[index];
          final isLocal = attendee.attendeeId == session.localAttendeeId;
          return SizedBox(
            width: 80,
            child: ParticipantTile(
              attendee: attendee,
              displayName: isLocal
                  ? 'You'
                  : session.roster[attendee.attendeeId],
              borderRadius: BorderRadius.circular(8),
              avatarSize: 32,
              isActiveSpeaker: session.isActiveSpeaker(
                attendee.attendeeId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _ConnectionBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.signal_cellular_connected_no_internet_4_bar,
            color: ChimeColors.surface,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: ChimeColors.surface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReconnectingOverlay extends StatelessWidget {
  const _ReconnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: ChimeColors.surface),
            SizedBox(height: 16),
            Text(
              'Reconnecting...',
              style: TextStyle(
                color: ChimeColors.surface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
