import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:provider/provider.dart';

class CameraToggle extends StatelessWidget {
  const CameraToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    final isVideoOn = session.isLocalVideoOn;
    final isFront = session.activeCameraFacing != 'back';
    final icon = isVideoOn
        ? (isFront ? Icons.videocam : Icons.camera_rear)
        : Icons.videocam_off;

    return GestureDetector(
      onLongPress: isVideoOn ? () => session.switchCamera() : null,
      child: FilledButton(
        style: Style.circleButton.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            isVideoOn
                ? ChimeColors.buttonBackground
                : ChimeColors.surfaceVariant,
          ),
        ),
        child: Icon(
          icon,
          color: isVideoOn ? ChimeColors.surface : ChimeColors.onSurface,
        ),
        onPressed: () {
          session.sendLocalVideoTileOn();
        },
      ),
    );
  }
}
