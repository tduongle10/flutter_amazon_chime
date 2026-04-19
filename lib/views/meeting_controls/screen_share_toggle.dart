import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:provider/provider.dart';

class ScreenShareToggle extends StatelessWidget {
  const ScreenShareToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    final isSharing = session.isLocalScreenSharing;

    final icon = isSharing ? Icons.stop_screen_share : Icons.screen_share;

    return FilledButton(
      style: Style.circleButton.copyWith(
        backgroundColor: WidgetStatePropertyAll(
          isSharing ? ChimeColors.buttonBackground : ChimeColors.surfaceVariant,
        ),
      ),
      child: Icon(
        icon,
        color: isSharing ? ChimeColors.surface : ChimeColors.onSurface,
      ),
      onPressed: () {
        session.sendLocalScreenShareToggle();
      },
    );
  }
}
