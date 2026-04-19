import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JoinInfo', () {
    const sample = JoinInfo(
      meetingId: 'meeting-1',
      externalMeetingId: 'ext-meeting-1',
      mediaRegion: 'us-east-1',
      audioHostUrl: 'https://audio.example',
      audioFallbackUrl: 'https://audio-fallback.example',
      signalingUrl: 'wss://signal.example',
      turnControlUrl: 'https://turn.example',
      externalUserId: 'app#alice',
      attendeeId: 'attendee-1',
      joinToken: 'join-token-1',
      appGroupId: 'group.com.retozu.app.screenshare',
      screenShareExtensionId: 'com.retozu.app.ScreenShareExt',
    );

    test('round-trips through toJson/fromJson', () {
      final decoded = JoinInfo.fromJson(sample.toJson());
      expect(decoded, sample);
    });

    test('omits optional fields from toJson when null', () {
      const minimal = JoinInfo(
        meetingId: 'm',
        externalMeetingId: 'em',
        mediaRegion: 'us-east-1',
        audioHostUrl: '',
        audioFallbackUrl: '',
        signalingUrl: '',
        turnControlUrl: '',
        externalUserId: '',
        attendeeId: '',
        joinToken: '',
      );
      final json = minimal.toJson();
      expect(json.containsKey('AppGroupId'), isFalse);
      expect(json.containsKey('ScreenShareExtensionId'), isFalse);
    });

    test('equality distinguishes screenShareExtensionId', () {
      final other = JoinInfo.fromJson({
        ...sample.toJson(),
        'ScreenShareExtensionId': 'com.retozu.app.DifferentExt',
      });
      expect(other, isNot(sample));
      expect(other.hashCode, isNot(sample.hashCode));
    });
  });
}
