import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';
import 'package:provider/provider.dart';

import '../api_service.dart';
import 'meeting_screen.dart';

class JoinMeetingScreen extends StatefulWidget {
  const JoinMeetingScreen({super.key});

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  final _meetingIdController = TextEditingController();
  final _attendeeNameController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _meetingIdController.dispose();
    _attendeeNameController.dispose();
    super.dispose();
  }

  Future<void> _joinMeeting() async {
    final meetingId = _meetingIdController.text.trim();
    final attendeeName = _attendeeNameController.text.trim();

    if (meetingId.isEmpty || attendeeName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both Meeting ID and your name.';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      // 1. Request permissions
      await AmazonChime.instance.requestAudioPermissions();
      await AmazonChime.instance.requestVideoPermissions();

      // 2. Call backend API
      final joinInfo = await ApiService.joinMeeting(meetingId, attendeeName);

      // 3. Join meeting via native SDK
      await AmazonChime.instance.joinMeeting(joinInfo);

      // 4. Initialize session state
      if (!mounted) return;
      final session = Provider.of<ChimeSession>(context, listen: false);
      session.initializeMeeting(
        joinInfo: joinInfo,
        roster: {joinInfo.attendeeId: attendeeName},
      );

      // 5. Navigate to meeting screen (deferred to avoid navigator lock
      // from the notifyListeners rebuild in initializeMeeting)
      if (!mounted) return;
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: session,
              child: MeetingScreen(meetingTitle: meetingId),
            ),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / Title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ChimeColors.buttonBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: ChimeColors.surface,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Amazon Chime',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join or create a meeting',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ChimeColors.onSurface),
              ),
              const SizedBox(height: 40),

              // Meeting ID field
              TextField(
                controller: _meetingIdController,
                decoration: InputDecoration(
                  fillColor: ChimeColors.surfaceVariant,
                  hintText: 'Enter meeting ID',
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Attendee Name field
              TextField(
                controller: _attendeeNameController,
                decoration: InputDecoration(
                  fillColor: ChimeColors.surfaceVariant,
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _joinMeeting(),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: ChimeColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Join button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isJoining ? null : _joinMeeting,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: ChimeColors.buttonBackground,
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: ChimeColors.surface,
                          ),
                        )
                      : const Text(
                          'Join Meeting',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
