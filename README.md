# flutter_amazon_chime

A Flutter plugin for Amazon Chime SDK meetings on iOS and Android.

> **Disclaimer:** This package is not affiliated with, endorsed by, or sponsored by Amazon Web Services (AWS). "Amazon Chime" is a trademark of Amazon.com, Inc.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Permissions Setup](#permissions-setup)
- [iOS Screen Share Setup](#ios-screen-share-setup)
- [Meeting Credentials](#meeting-credentials)
- [Usage Levels](#usage-levels)
  - [Level 1 — Drop-in UI (AmazonChimeView)](#level-1--drop-in-ui-amazonchimeview)
  - [Level 2 — Custom UI with ChimeSession](#level-2--custom-ui-with-chimesession)
  - [Level 3 — Fully Headless (AmazonChime.instance)](#level-3--fully-headless-amazonchimeinstance)
- [Data Messages](#data-messages)
- [Audio Device Management](#audio-device-management)
- [Meeting Quality & Analytics](#meeting-quality--analytics)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)
- [Models Reference](#models-reference)
- [Streams Reference](#streams-reference)

---

## Quick Start

The fastest way to get a meeting running:

```dart
import 'package:flutter_amazon_chime/flutter_amazon_chime.dart';
import 'package:provider/provider.dart';

// 1. Request permissions before joining
await AmazonChime.instance.requestAudioPermissions();
await AmazonChime.instance.requestVideoPermissions();

// 2. Join the meeting
await AmazonChime.instance.joinMeeting(joinInfo);

// 3. Initialize the session with the roster (attendeeId → display name)
session.initializeMeeting(
  joinInfo: joinInfo,
  roster: {'attendee-id-123': 'Alice', 'attendee-id-456': 'Bob'},
);

// 4. Show the built-in meeting UI
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider(
      create: (_) => ChimeSession(),
      child: AmazonChimeView(
        title: 'My Meeting',
        onLeave: () => Navigator.pop(context),
      ),
    ),
  ),
);
```

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_amazon_chime: ^<version>
  provider: ^6.0.0
```

---

## Permissions Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
<!-- Android 13+ only, for screen share notification -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for meeting audio.</string>
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for video.</string>
```

### Requesting permissions at runtime

Check and request permissions before joining. Calling `joinMeeting` without audio permissions will fail.

```dart
// Check without prompting the user
final hasAudio = await AmazonChime.instance.hasAudioPermissions();
final hasVideo = await AmazonChime.instance.hasVideoPermissions();

// Show the system permission dialog
await AmazonChime.instance.requestAudioPermissions(); // throws ChimePermissionException if denied
await AmazonChime.instance.requestVideoPermissions(); // throws ChimePermissionException if denied
```

---

## iOS Screen Share Setup

Screen sharing on iOS requires a Broadcast Upload Extension target and an App Group shared between the extension and your main app. This is an Apple platform requirement — the plugin cannot ship the extension target for you.

### Steps

1. In Xcode, add a new target: **File → New → Target → Broadcast Upload Extension**. Any name works (the examples below assume `ScreenShareExt`).

2. Enable the **App Groups** capability on *both* the main app target and the extension target, and use the same group ID on both (e.g. `group.com.example.app.screenshare`).

3. In your extension's `SampleHandler.swift`, read meeting credentials from the shared `UserDefaults(suiteName:)` and forward sample buffers to Chime. The plugin writes the credentials to the App Group automatically when `joinMeeting` is called.

4. Pass `appGroupId` on `JoinInfo`:

   ```dart
   final joinInfo = JoinInfo(
     // ... other fields ...
     appGroupId: 'group.com.example.app.screenshare', // iOS only
   );
   ```

### Naming the extension

The plugin needs to know your extension's bundle ID in order to present the system broadcast picker. It resolves it in this order:

1. `JoinInfo.screenShareExtensionId` (if set), e.g. `'com.example.app.MyBroadcastExt'`.
2. `ChimeScreenShareExtension` key in the main app's `Info.plist`.
3. Fallback: `<mainAppBundleId>.ScreenShareExt`.

If your extension is named `ScreenShareExt` and sits under your main app's bundle ID you don't need to do anything. Otherwise pick one of the overrides:

```dart
// Per-meeting override
final joinInfo = JoinInfo(
  // ... other fields ...
  appGroupId: 'group.com.example.app.screenshare',
  screenShareExtensionId: 'com.example.app.MyBroadcastExt',
);
```

```xml
<!-- ios/Runner/Info.plist — app-wide override -->
<key>ChimeScreenShareExtension</key>
<string>com.example.app.MyBroadcastExt</string>
```

Android screen share does not require any additional setup.

---

## Meeting Credentials

`JoinInfo` holds all credentials returned by your server after creating a meeting and attendee via the AWS Chime API.

```dart
final joinInfo = JoinInfo(
  meetingId: 'abc-123',
  externalMeetingId: 'my-room',
  mediaRegion: 'us-east-1',
  audioHostUrl: 'https://...',
  audioFallbackUrl: 'https://...',
  signalingUrl: 'wss://...',
  turnControlUrl: 'https://...',
  attendeeId: 'attendee-id-123',
  externalUserId: 'app#alice',   // convention: "appId#username"
  joinToken: 'join-token-abc',
  appGroupId: 'group.com.example.app.screenshare',         // iOS screen share only
  screenShareExtensionId: 'com.example.app.ScreenShareExt', // iOS screen share only — optional
);
```

`JoinInfo.fromJson` parses the AWS Chime API response directly:

```dart
final joinInfo = JoinInfo.fromJson(responseJson);
```

---

## Usage Levels

### Level 1 — Drop-in UI (AmazonChimeView)

`AmazonChimeView` provides a complete, production-ready meeting UI out of the box:

- **Participant grid** — adapts layout for 1 to 7+ participants
- **Meeting controls** — mute, video toggle, camera switch (long-press the video button), audio device picker, screen share, leave
- **Screen share** — full-screen content view with participant strip
- **Connection quality banner** — shown when connection degrades
- **Reconnecting overlay** — shown during audio session recovery
- **Active speaker highlighting** — border highlight on the active speaker tile

```dart
ChangeNotifierProvider(
  create: (_) => ChimeSession(),
  child: AmazonChimeView(
    title: 'My Meeting',           // optional — displayed at the top
    onLeave: () {},                // optional — called after meeting stops and view pops
    tileBuilder: (ctx, attendee, isLocal) {  // optional — custom participant tile
      return MyCustomTile(attendee: attendee, isLocal: isLocal);
    },
  ),
)
```

**Important:** `AmazonChimeView` requires a `ChimeSession` ancestor in the widget tree. Wrap it with `ChangeNotifierProvider<ChimeSession>` as shown above.

Call `session.initializeMeeting(...)` after `joinMeeting` to populate the roster before pushing `AmazonChimeView`.

---

### Level 2 — Custom UI with ChimeSession

Use `ChimeSession` directly to build your own layout while still getting automatic state management. All state updates trigger `notifyListeners()`.

```dart
final session = context.watch<ChimeSession>();
```

**State available on ChimeSession:**

| Property | Type | Description |
|---|---|---|
| `isMeetingActive` | `bool` | Whether a meeting is currently active |
| `localAttendeeId` | `String?` | The local attendee's ID |
| `localAttendee` | `Attendee?` | The local attendee object |
| `isLocalMuted` | `bool` | Whether the local attendee is muted |
| `isLocalVideoOn` | `bool` | Whether local video is active |
| `currAttendees` | `Map<String, Attendee>` | All attendees keyed by ID (read-only view) |
| `allParticipants` | `List<Attendee>` | All attendees excluding content share |
| `remoteAttendees` | `List<Attendee>` | Remote attendees only |
| `participantCount` | `int` | Total participant count |
| `roster` | `Map<String, String>` | attendeeId → display name (read-only view) |
| `activeSpeakers` | `List<String>` | Currently active speaker IDs (read-only view) |
| `isActiveSpeaker(id)` | `bool` | Check if an attendee is speaking |
| `activeCameraFacing` | `String?` | `"front"`, `"back"`, or `null` |
| `isConnectionPoor` | `bool` | Connection quality degraded |
| `isReconnecting` | `bool` | Audio session is reconnecting |
| `shouldShowScreenShare` | `bool` | A remote screen share is active |
| `isLocalScreenSharing` | `bool` | Local attendee is sharing their screen |
| `deviceList` | `List<String>` | Available audio device labels (read-only view) |
| `selectedAudioDevice` | `String?` | Currently active audio device label |

**Actions available on ChimeSession:**

All action methods return `Future<void>` and rethrow on failure after logging, so you can `await` and catch them if you need error handling. Fire-and-forget usage (no `await`) is also safe.

```dart
session.initializeMeeting(joinInfo: joinInfo, roster: roster);

// Fire-and-forget (errors logged internally)
session.sendLocalMuteToggle();
session.sendLocalVideoTileOn();
session.switchCamera();
session.sendLocalScreenShareToggle();
session.updateCurrentDevice(deviceLabel);
session.stopMeeting();

// Awaited with error handling
try {
  await session.sendLocalMuteToggle();
} on ChimeDeviceException catch (e) {
  showError(e.message);
}
```

**Reusable sub-widgets:**

These are the same widgets used inside `AmazonChimeView`, available for custom layouts:

```dart
// Display a single participant's video (or avatar if video is off)
ParticipantTile(
  attendee: attendee,
  displayName: 'Alice',
  isActiveSpeaker: session.isActiveSpeaker(attendee.attendeeId),
)

// Display a raw video tile by tile ID
VideoTile(tileId: attendee.videoTileInfo?.tileId)

// Adaptive multi-participant grid
ParticipantGrid(
  participants: session.allParticipants,
  localAttendeeId: session.localAttendeeId,
  roster: session.roster,
  activeSpeakers: session.activeSpeakers.toSet(),
)

// The full meeting controls bar
MeetingControls()
```

**Example — custom layout:**

```dart
Scaffold(
  body: Column(
    children: [
      Expanded(
        child: ParticipantGrid(
          participants: session.allParticipants,
          localAttendeeId: session.localAttendeeId,
          roster: session.roster,
          activeSpeakers: session.activeSpeakers.toSet(),
        ),
      ),
      MeetingControls(),
    ],
  ),
)
```

---

### Level 3 — Fully Headless (AmazonChime.instance)

Skip `AmazonChimeView` and `ChimeSession` entirely. Call the SDK directly and manage all state yourself.

#### Meeting lifecycle

```dart
await AmazonChime.instance.joinMeeting(joinInfo);
await AmazonChime.instance.stopMeeting();
```

#### Audio

```dart
await AmazonChime.instance.mute();
await AmazonChime.instance.unmute();

final devices = await AmazonChime.instance.listAudioDevices(); // List<String>
final current = await AmazonChime.instance.initialAudioSelection(); // String
await AmazonChime.instance.updateAudioDevice('Speaker'); // by label
```

#### Video

```dart
await AmazonChime.instance.startLocalVideo();
await AmazonChime.instance.stopLocalVideo();
await AmazonChime.instance.switchCamera();

final facing = await AmazonChime.instance.activeCamera(); // "front", "back", or null

// Limit video bandwidth (0 = SDK default)
await AmazonChime.instance.setLocalVideoMaxBitrate(500); // kbps
```

#### Remote video subscriptions

Subscribe to remote attendees' video. Call this in response to `onRemoteVideoSourcesAvailable`:

```dart
AmazonChime.instance.onRemoteVideoSourcesAvailable.listen((sources) async {
  await AmazonChime.instance.updateVideoSourceSubscriptions(toAdd: sources);
});

AmazonChime.instance.onRemoteVideoSourcesUnavailable.listen((sources) async {
  await AmazonChime.instance.updateVideoSourceSubscriptions(
    toAdd: [],
    toRemove: sources,
  );
});
```

#### Screen share

```dart
await AmazonChime.instance.startScreenShare();
await AmazonChime.instance.stopScreenShare();
```

#### Listening to events

```dart
AmazonChime.instance.onAttendeeJoined.listen((attendee) { });
AmazonChime.instance.onAttendeeLeft.listen((attendee) { });
AmazonChime.instance.onAttendeeMuted.listen((attendee) { });
AmazonChime.instance.onVideoTileAdded.listen((tile) { });
AmazonChime.instance.onActiveSpeakersChanged.listen((ids) { });
AmazonChime.instance.onConnectionQualityChanged.listen((isPoor) { });
AmazonChime.instance.onAudioSessionStarted.listen((_) { });
AmazonChime.instance.onAudioSessionStopped.listen((_) { });
// See full list in Streams Reference below
```

---

## Data Messages

Data messages let attendees exchange arbitrary real-time payloads on named topics. Common uses: chat, emoji reactions, polls, whiteboard sync.

### Sending

```dart
await AmazonChime.instance.sendDataMessage(
  'chat',          // topic name
  'Hello!',        // UTF-8 string payload
  lifetimeMs: 0,   // 0 = not retained for late joiners; max 300,000 ms
);
```

### Receiving

```dart
AmazonChime.instance.onDataMessageReceived.listen((DataMessage msg) {
  print('${msg.senderExternalUserId} on ${msg.topic}: ${msg.data}');
  if (msg.throttled) {
    // message was throttled server-side, handle gracefully
  }
});
```

**`DataMessage` fields:**

| Field | Type | Description |
|---|---|---|
| `topic` | `String` | The topic the message was sent on |
| `data` | `String` | The UTF-8 string payload |
| `senderAttendeeId` | `String` | Sender's Chime attendee ID |
| `senderExternalUserId` | `String` | Sender's external user ID |
| `timestampMs` | `int` | Server timestamp (ms since epoch) |
| `throttled` | `bool` | Whether the server throttled this message |

---

## Audio Device Management

```dart
// List available devices (speakers, Bluetooth, wired headset, etc.)
final List<String> devices = await AmazonChime.instance.listAudioDevices();

// Get the currently active device
final String current = await AmazonChime.instance.initialAudioSelection();

// Switch to a specific device by label
await AmazonChime.instance.updateAudioDevice('Bluetooth Headset');
```

When using `ChimeSession`, the device list is managed automatically. Use `session.deviceList`, `session.selectedAudioDevice`, and `session.updateCurrentDevice(label)`.

---

## Meeting Quality & Analytics

### Periodic metrics

Emitted every second with a map of metric name → numeric value.

```dart
AmazonChime.instance.onMeetingMetricsReceived.listen((Map<String, Object?> metrics) {
  final loss = metrics['audioPacketsReceivedFractionLoss'];
  final jitter = metrics['audioDecodeMs'];
});
```

### SDK lifecycle events

Emitted for key meeting lifecycle moments (join, leave, reconnect, etc.).

```dart
AmazonChime.instance.onMeetingEventReceived.listen((MeetingEvent event) {
  print('${event.name}: ${event.attributes}');
});
```

**`MeetingEvent` fields:**

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Event name (e.g. `"meetingStartSucceeded"`) |
| `attributes` | `Map<String, Object?>` | Event-specific attribute map |

### Volume & signal strength

```dart
// Batch updates emitted periodically for all attendees
AmazonChime.instance.onAttendeesVolumeChanged.listen((List<AttendeeVolume> updates) {
  for (final u in updates) {
    print('${u.attendeeId}: volume=${u.volume}');
  }
});

AmazonChime.instance.onAttendeesSignalChanged.listen((List<AttendeeSignal> updates) {
  for (final u in updates) {
    print('${u.attendeeId}: signal=${u.signalStrength}');
  }
});
```

### Connection quality

```dart
AmazonChime.instance.onConnectionQualityChanged.listen((bool isPoor) {
  if (isPoor) showBanner('Poor connection');
  else hideBanner();
});
```

---

## Error Handling

All SDK methods throw typed exceptions on failure.

| Exception | When thrown |
|---|---|
| `ChimePermissionException` | Audio or video permissions denied |
| `ChimeMeetingException` | Join or stop meeting failed |
| `ChimeDeviceException` | Mute, video, audio device, or screen share failed |
| `ChimeStateException` | SDK reached an invalid state |

All extend `ChimeException`, which exposes `message` and an optional `code`.

```dart
try {
  await AmazonChime.instance.joinMeeting(joinInfo);
} on ChimeMeetingException catch (e) {
  print('Join failed: ${e.message} (${e.code})');
} on ChimePermissionException catch (e) {
  print('Permission denied: ${e.message}');
}
```

---

## Troubleshooting

### Joined the meeting but no audio
- **Android**: confirm `RECORD_AUDIO` is in your app's `AndroidManifest.xml` and was granted at runtime. Permissions denied silently fail — call `hasAudioPermissions()` to check.
- **iOS**: confirm `NSMicrophoneUsageDescription` is in `Info.plist`. Without it, iOS rejects the permission prompt and the audio session never opens.

### Audio cuts out when the app goes to background (iOS)
Add the background audio mode to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Remote video tiles are black or never appear
The SDK does not auto-subscribe to remote video. Listen to `onRemoteVideoSourcesAvailable` and call `updateVideoSourceSubscriptions(toAdd: sources)`. See [Remote video subscriptions](#remote-video-subscriptions).

### iOS screen share picker doesn't appear when calling `startScreenShare()`
The plugin is looking for an extension bundle ID it can't find. Verify the resolution order:
1. Did you pass `JoinInfo.screenShareExtensionId`?
2. Is `ChimeScreenShareExtension` set in your main app's `Info.plist`?
3. If relying on the fallback, is your extension target's bundle ID exactly `<mainAppBundleId>.ScreenShareExt`?

### iOS screen share starts then immediately stops
App Group ID mismatch. The same group ID must be enabled on **both** the main app target and the extension target, and `appGroupId` on `JoinInfo` must match it exactly. Check **Signing & Capabilities → App Groups** on both targets.

### Bluetooth headset isn't in the audio device list (Android 12+)
The plugin declares `BLUETOOTH_CONNECT` but it's a runtime permission. Request it in your app before joining; without it, the Android system returns no Bluetooth devices.

### `MissingPluginException` after adding the plugin
Run `flutter clean && flutter pub get`, then rebuild. Plugin registration is a build-time step.

---

## Models Reference

### `JoinInfo`
Meeting and attendee credentials returned by your server. See [Meeting Credentials](#meeting-credentials).

### `Attendee`

| Member | Type | Description |
|---|---|---|
| `attendeeId` | `String` | Chime attendee ID |
| `externalUserId` | `String` | Your app's user identifier (format: `"appId#username"`) |
| `muteStatus` | `bool` | Whether the attendee is currently muted |
| `isVideoOn` | `bool` | Whether the attendee has video enabled |
| `videoTileInfo` | `VideoTileInfo?` | Current video tile, or null if video is off |
| `formattedExternalId` | `String` *(getter)* | The username portion of `externalUserId` — splits on `#` and returns the second part, or the full value if the convention isn't followed |
| `isContent` | `bool` *(getter)* | Whether this attendee represents a screen share source |
| `Attendee.isContentId(id)` | `bool` *(static)* | Whether a raw attendee ID string represents a content share |

### `VideoTileInfo`

| Field | Type | Description |
|---|---|---|
| `tileId` | `int` | Native tile ID — pass to `VideoTile(tileId:)` |
| `attendeeId` | `String` | Owner of this tile |
| `isLocalTile` | `bool` | Whether this is the local attendee's tile |
| `isContentShare` | `bool` | Whether this tile is a screen share |
| `videoStreamContentWidth` | `int` | Stream pixel width |
| `videoStreamContentHeight` | `int` | Stream pixel height |

### `RemoteVideoSource`

| Field | Type | Description |
|---|---|---|
| `attendeeId` | `String` | Attendee whose video you want to subscribe to |

### `DataMessage`
See [Data Messages](#data-messages).

### `AttendeeVolume`

| Field | Type | Description |
|---|---|---|
| `attendeeId` | `String` | Chime attendee ID |
| `externalUserId` | `String` | Your app's user identifier |
| `volume` | `int` | Volume level (0–100) |

### `AttendeeSignal`

| Field | Type | Description |
|---|---|---|
| `attendeeId` | `String` | Chime attendee ID |
| `externalUserId` | `String` | Your app's user identifier |
| `signalStrength` | `int` | Signal strength (0–2) |

### `MeetingEvent`
See [Meeting Quality & Analytics](#meeting-quality--analytics).

---

## Streams Reference

All streams on `AmazonChime.instance` are broadcast streams — multiple listeners are supported and each subscription must be cancelled when no longer needed.

| Stream | Type | Description |
|---|---|---|
| `onAttendeeJoined` | `Stream<Attendee>` | A new attendee joined |
| `onAttendeeLeft` | `Stream<Attendee>` | An attendee left gracefully |
| `onAttendeeDropped` | `Stream<Attendee>` | An attendee was dropped (network) |
| `onAttendeeMuted` | `Stream<Attendee>` | An attendee muted themselves |
| `onAttendeeUnmuted` | `Stream<Attendee>` | An attendee unmuted themselves |
| `onVideoTileAdded` | `Stream<VideoTileInfo>` | A video tile became available |
| `onVideoTileRemoved` | `Stream<VideoTileInfo>` | A video tile was removed |
| `onVideoTilePaused` | `Stream<VideoTileInfo>` | A video tile was paused |
| `onVideoTileResumed` | `Stream<VideoTileInfo>` | A paused tile resumed |
| `onActiveSpeakersChanged` | `Stream<List<String>>` | Active speaker IDs changed |
| `onAttendeesVolumeChanged` | `Stream<List<AttendeeVolume>>` | Batch volume updates |
| `onAttendeesSignalChanged` | `Stream<List<AttendeeSignal>>` | Batch signal strength updates |
| `onRemoteVideoSourcesAvailable` | `Stream<List<RemoteVideoSource>>` | Remote video sources became available |
| `onRemoteVideoSourcesUnavailable` | `Stream<List<RemoteVideoSource>>` | Remote video sources went away |
| `onAudioSessionStarted` | `Stream<void>` | Audio session started (or reconnected successfully) |
| `onAudioSessionStopped` | `Stream<void>` | Audio session ended |
| `onAudioSessionDropped` | `Stream<void>` | Audio session was dropped |
| `onAudioSessionStartConnecting` | `Stream<bool>` | Connecting (or reconnecting if `true`) |
| `onAudioSessionCancelledReconnect` | `Stream<void>` | Reconnect attempt was cancelled |
| `onConnectionQualityChanged` | `Stream<bool>` | `true` = poor, `false` = recovered |
| `onContentShareStateChanged` | `Stream<int>` | `0` = started, `1` = stopped |
| `onDataMessageReceived` | `Stream<DataMessage>` | Received a real-time data message |
| `onMeetingMetricsReceived` | `Stream<Map<String, Object?>>` | Periodic quality metrics |
| `onMeetingEventReceived` | `Stream<MeetingEvent>` | SDK lifecycle analytics event |
