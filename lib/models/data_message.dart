/// A real-time data message received from another attendee.
class DataMessage {
  /// The topic/channel the message was sent on.
  final String topic;

  /// The UTF-8 string payload.
  final String data;

  final String senderAttendeeId;
  final String senderExternalUserId;

  /// Server timestamp in milliseconds since epoch.
  final int timestampMs;

  /// True if the message was throttled by the server.
  final bool throttled;

  const DataMessage({
    required this.topic,
    required this.data,
    required this.senderAttendeeId,
    required this.senderExternalUserId,
    required this.timestampMs,
    required this.throttled,
  });
}
