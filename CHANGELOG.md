## 0.1.2

* Tighten dependency lower bounds so the package actually compiles against its declared minimums. Previously `logger: ^2.0.0` allowed `2.0.0`, which did not contain `DateTimeFormat`. No public API changes.

## 0.1.1

* Bump `logger` constraint to `^2.0.0` to stay on the latest upstream version. No public API changes.

## 0.1.0

* Initial public release.
* Audio and video meetings on iOS and Android via the Amazon Chime SDK.
* Screen sharing on both platforms. On iOS, `JoinInfo.screenShareExtensionId` or the `ChimeScreenShareExtension` Info.plist key overrides the default `<mainBundleId>.ScreenShareExt` suffix so the broadcast upload extension target can be named anything.
* Three usage tiers: drop-in `AmazonChimeView`, custom UI with `ChimeSession`, or fully headless via `AmazonChime.instance` streams and methods.
* Real-time data messages, active speaker detection, connection quality signals, audio device management, and periodic meeting-quality metrics.
* Typed exceptions (`ChimePermissionException`, `ChimeMeetingException`, `ChimeDeviceException`, `ChimeStateException`) for structured error handling.
