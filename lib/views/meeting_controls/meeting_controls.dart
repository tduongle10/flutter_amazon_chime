import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/audio_output_button.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/camera_toggle.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/call_end_button.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/mic_toggle.dart';
import 'package:flutter_amazon_chime/views/meeting_controls/screen_share_toggle.dart';

// MeetingControls visual constants
const _kBarPadding = 8.0;

class MeetingControls extends StatelessWidget {
  const MeetingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_kBarPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          AudioOutputButton(),
          MicToggle(),
          CameraToggle(),
          ScreenShareToggle(),
          CallEndButton(),
        ],
      ),
    );
  }
}
