import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:provider/provider.dart';

class MicStatusIndicator extends StatelessWidget {
  final String? attendeeId;
  const MicStatusIndicator({super.key, required this.attendeeId});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    final isMuted = session.currAttendees[attendeeId]?.muteStatus == true;

    final icon = isMuted ? Icons.mic_off : Icons.mic;

    return Icon(
      icon,
      color: ChimeColors.surface,
      size: 24,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: 4,
        ),
      ],
    );
  }
}
