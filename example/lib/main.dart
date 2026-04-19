import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';
import 'package:provider/provider.dart';

import 'screens/join_meeting_screen.dart';

void main() {
  runApp(const ChimeExampleApp());
}

class ChimeExampleApp extends StatelessWidget {
  const ChimeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChimeSession(),
      child: MaterialApp(
        title: 'Amazon Chime SDK Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: ChimeColors.buttonBackground,
          useMaterial3: true,
        ),
        home: const JoinMeetingScreen(),
      ),
    );
  }
}
