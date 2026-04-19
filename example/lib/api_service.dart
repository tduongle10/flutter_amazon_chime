import 'dart:convert';
import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiService {
  static final String _baseUrl = ApiConfig.apiUrl;
  static final String _region = ApiConfig.region;

  /// Calls the serverless demo backend to join (or create) a meeting.
  /// Returns a [JoinInfo] on success, or throws on failure.
  static Future<JoinInfo> joinMeeting(
      String meetingId, String attendeeName) async {
    final encodedTitle = Uri.encodeComponent(meetingId);
    final encodedName = Uri.encodeComponent(attendeeName);
    final encodedRegion = Uri.encodeComponent(_region);

    final url =
        "${_baseUrl}join?title=$encodedTitle&name=$encodedName&region=$encodedRegion";

    final response = await http.post(Uri.parse(url));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return JoinInfo.fromJson(_flattenJoinResponse(json));
    } else {
      throw Exception(
          'Failed to join meeting. Status: ${response.statusCode}\nMessage: ${response.body}');
    }
  }

  /// The serverless backend returns a nested JSON structure.
  /// This flattens it into the format expected by [JoinInfo.fromJson].
  static Map<String, dynamic> _flattenJoinResponse(
      Map<String, dynamic> json) {
    final meetingMap = json['JoinInfo']['Meeting']['Meeting'];
    final mediaPlacement = meetingMap['MediaPlacement'];
    final attendeeMap = json['JoinInfo']['Attendee']['Attendee'];

    return {
      'MeetingId': meetingMap['MeetingId'],
      'ExternalMeetingId': meetingMap['ExternalMeetingId'],
      'MediaRegion': meetingMap['MediaRegion'],
      'AudioHostUrl': mediaPlacement['AudioHostUrl'],
      'AudioFallbackUrl': mediaPlacement['AudioFallbackUrl'],
      'SignalingUrl': mediaPlacement['SignalingUrl'],
      'TurnControlUrl': mediaPlacement['TurnControlUrl'],
      'ExternalUserId': attendeeMap['ExternalUserId'],
      'AttendeeId': attendeeMap['AttendeeId'],
      'JoinToken': attendeeMap['JoinToken'],
      'AppGroupId': ApiConfig.appGroupId,
    };
  }
}
