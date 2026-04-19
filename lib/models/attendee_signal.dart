/// Signal strength for a single attendee.
/// [signalStrength]: 0=none, 1=low, 2=high
class AttendeeSignal {
  final String attendeeId;
  final String externalUserId;
  final int signalStrength;

  const AttendeeSignal({
    required this.attendeeId,
    required this.externalUserId,
    required this.signalStrength,
  });
}
