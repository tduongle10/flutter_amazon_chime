class ApiConfig {
  /// Base URL for the Amazon Chime SDK serverless demo backend.
  /// Format: `https://<api-id>.execute-api.<aws-region-id>.amazonaws.com/Prod/`
  static String get apiUrl => "";

  /// AWS region for creating meetings.
  static String get region => "us-east-1";

  /// iOS App Group ID shared between the main app and the ScreenShareExt
  /// broadcast extension. Must match the App Group configured in Xcode
  /// Signing & Capabilities for both targets.
  static String get appGroupId =>
      "group.com.retozu.flutterChimeExample.screenshare";
}
