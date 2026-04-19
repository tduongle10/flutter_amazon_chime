import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:provider/provider.dart';

class MicToggle extends StatelessWidget {
  const MicToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    final isMuted = session.isLocalMuted;

    final icon = isMuted ? Icons.mic_off : Icons.mic;

    return FilledButton(
      style: Style.circleButton.copyWith(
        backgroundColor: WidgetStatePropertyAll(
          isMuted ? ChimeColors.surfaceVariant : ChimeColors.buttonBackground,
        ),
      ),
      child: Icon(
        icon,
        color: isMuted ? ChimeColors.onSurface : ChimeColors.surface,
      ),
      onPressed: () {
        session.sendLocalMuteToggle();
      },
    );
  }
}
