import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';

class MeetingScreen extends StatelessWidget {
  final String meetingTitle;
  const MeetingScreen({super.key, required this.meetingTitle});

  @override
  Widget build(BuildContext context) {
    return AmazonChimeView(title: meetingTitle);
  }
}
