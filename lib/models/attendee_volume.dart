/// Volume level for a single attendee.
/// [volume]: 0=muted, 1=notSpeaking, 2=low, 3=medium, 4=high
class AttendeeVolume {
  final String attendeeId;
  final String externalUserId;
  final int volume;

  const AttendeeVolume({
    required this.attendeeId,
    required this.externalUserId,
    required this.volume,
  });
}
