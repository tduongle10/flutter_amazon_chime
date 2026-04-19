/// Base exception for all Amazon Chime SDK errors.
abstract class ChimeException implements Exception {
  /// A descriptive message for the error.
  final String message;

  /// Optional underlying error code or native platform details.
  final String? code;

  const ChimeException(this.message, [this.code]);

  @override
  String toString() => 'ChimeException($code): $message';
}

/// Thrown when audio or video permissions are denied or restricted.
class ChimePermissionException extends ChimeException {
  const ChimePermissionException(super.message, [super.code]);
}

/// Thrown when starting, stopping, or joining a meeting fails.
class ChimeMeetingException extends ChimeException {
  const ChimeMeetingException(super.message, [super.code]);
}

/// Thrown when device configuration (e.g., audio route, mute, video) fails.
class ChimeDeviceException extends ChimeException {
  const ChimeDeviceException(super.message, [super.code]);
}

/// Thrown when the Chime meeting is out of sync or an invalid state is reached.
class ChimeStateException extends ChimeException {
  const ChimeStateException(super.message, [super.code]);
}
