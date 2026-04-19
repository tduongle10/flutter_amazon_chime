/// A structured meeting analytics event emitted by the Chime SDK.
class MeetingEvent {
  const MeetingEvent({required this.name, required this.attributes});

  /// The event name (e.g. "meetingStartSucceeded", "meetingFailed").
  final String name;

  /// Key-value attributes describing the event. Values may be String, int,
  /// double, or bool depending on the attribute.
  final Map<String, Object?> attributes;
}
