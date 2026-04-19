import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/amazon_chime.dart';
import 'package:flutter_amazon_chime/models/models.dart';
import 'logger.dart';

// ─── Internal state containers ───────────────────────────────────────────────
// These are private to this file. ChimeSession delegates to them to keep
// each concern in one place while exposing a single ChangeNotifier to users.

class _MeetingState {
  bool isActive = false;
  bool isConnectionPoor = false;
  bool isReconnecting = false;

  void reset() {
    isActive = false;
    isConnectionPoor = false;
    isReconnecting = false;
  }
}

class _AttendeeState {
  String? localId;
  Map<String, Attendee> attendees = {};
  Map<String, String> roster = {};
  List<String> activeSpeakers = [];

  void reset() {
    localId = null;
    attendees = {};
    roster = {};
    activeSpeakers = [];
  }
}

class _VideoState {
  String? contentAttendeeId;
  bool isReceivingScreenShare = false;
  String? activeCameraFacing;

  void reset() {
    contentAttendeeId = null;
    isReceivingScreenShare = false;
    activeCameraFacing = null;
  }
}

class _AudioState {
  String? selectedDevice;
  List<String> deviceList = [];

  void reset() {
    selectedDevice = null;
    deviceList = [];
  }
}

// ─── ChimeSession ────────────────────────────────────────────────────────────

/// A `ChangeNotifier` that holds the state of a single Chime meeting session
/// and exposes actions that proxy to [AmazonChime.instance].
///
/// This is an opt-in convenience for apps using `package:provider`. Apps using
/// BLoC, Riverpod, or any other state solution can ignore this class and wire
/// the raw `Stream`s and `Future`-returning methods on [AmazonChime.instance]
/// into their own state containers.
class ChimeSession extends ChangeNotifier with WidgetsBindingObserver {
  final _meeting = _MeetingState();
  final _attendees = _AttendeeState();
  final _video = _VideoState();
  final _audio = _AudioState();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ── Meeting state ──────────────────────────────────────────────────────────

  bool get isMeetingActive => _meeting.isActive;
  bool get isConnectionPoor => _meeting.isConnectionPoor;
  bool get isReconnecting => _meeting.isReconnecting;

  // ── Attendee state ─────────────────────────────────────────────────────────

  String? get localAttendeeId => _attendees.localId;
  Map<String, Attendee> get currAttendees => Map.unmodifiable(_attendees.attendees);
  Map<String, String> get roster => Map.unmodifiable(_attendees.roster);
  List<String> get activeSpeakers => List.unmodifiable(_attendees.activeSpeakers);

  bool get hasLocalAttendee =>
      _attendees.localId != null &&
      _attendees.attendees.containsKey(_attendees.localId);

  Attendee? get localAttendee =>
      _attendees.localId != null ? _attendees.attendees[_attendees.localId] : null;

  bool get isLocalMuted => _attendees.attendees[_attendees.localId]?.muteStatus == true;

  List<String> get remoteAttendeeIds => _attendees.attendees.keys
      .where((id) => id != _attendees.localId && !Attendee.isContentId(id))
      .toList();

  List<Attendee> get remoteAttendees =>
      remoteAttendeeIds.map((id) => _attendees.attendees[id]!).toList();

  List<Attendee> get allParticipants =>
      _attendees.attendees.values.where((a) => !a.isContent).toList();

  int get participantCount => allParticipants.length;
  bool get hasRemoteAttendees => remoteAttendeeIds.isNotEmpty;

  bool isActiveSpeaker(String attendeeId) =>
      _attendees.activeSpeakers.contains(attendeeId);

  // ── Video state ────────────────────────────────────────────────────────────

  String? get contentAttendeeId => _video.contentAttendeeId;
  bool get isReceivingScreenShare => _video.isReceivingScreenShare;
  String? get activeCameraFacing => _video.activeCameraFacing;

  bool get isLocalVideoOn =>
      _attendees.attendees[_attendees.localId]?.isVideoOn == true;

  bool get shouldShowLocalVideo =>
      isLocalVideoOn &&
      _attendees.attendees[_attendees.localId]?.videoTileInfo != null;

  bool get hasContentAttendee =>
      _video.contentAttendeeId != null &&
      _attendees.attendees.containsKey(_video.contentAttendeeId);

  bool get isLocalScreenSharing {
    final localId = _attendees.localId;
    final contentId = _video.contentAttendeeId;
    if (localId == null || contentId == null) return false;
    return contentId.startsWith(localId);
  }

  bool get shouldShowScreenShare =>
      hasContentAttendee && _video.isReceivingScreenShare && !isLocalScreenSharing;

  bool get hasContentVideoTile =>
      hasContentAttendee &&
      _attendees.attendees[_video.contentAttendeeId]?.videoTileInfo != null;

  // ── Audio state ────────────────────────────────────────────────────────────

  String? get selectedAudioDevice => _audio.selectedDevice;
  List<String> get deviceList => List.unmodifiable(_audio.deviceList);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  ChimeSession() {
    WidgetsBinding.instance.addObserver(this);
    _setupListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    if (_meeting.isActive) stopMeeting();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && _meeting.isActive) {
      stopMeeting();
    }
  }

  void _setupListeners() {
    final chime = AmazonChime.instance;
    _subscriptions.addAll([
      chime.onAttendeeJoined.listen(_onAttendeeJoined),
      chime.onAttendeeLeft.listen((a) => _onAttendeeLeftOrDropped(a, dropped: false)),
      chime.onAttendeeDropped.listen((a) => _onAttendeeLeftOrDropped(a, dropped: true)),
      chime.onAttendeeMuted.listen((a) => _changeMuteStatus(a, mute: true)),
      chime.onAttendeeUnmuted.listen((a) => _changeMuteStatus(a, mute: false)),
      chime.onVideoTileAdded.listen(_onVideoTileAdded),
      chime.onVideoTileRemoved.listen(_onVideoTileRemoved),
      chime.onAudioSessionStarted.listen((_) => _onAudioSessionStarted()),
      chime.onAudioSessionStopped.listen((_) => _onAudioSessionStopped()),
      chime.onActiveSpeakersChanged.listen(_onActiveSpeakersChanged),
      chime.onConnectionQualityChanged.listen(_onConnectionQualityChanged),
      chime.onAudioSessionStartConnecting.listen(_onAudioSessionStartConnecting),
      chime.onAudioSessionDropped.listen((_) => _onAudioSessionDropped()),
      chime.onAudioSessionCancelledReconnect.listen((_) => _onAudioSessionCancelledReconnect()),
      chime.onVideoTilePaused.listen(_onVideoTilePaused),
      chime.onVideoTileResumed.listen(_onVideoTileResumed),
    ]);
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  void initializeMeeting({
    required JoinInfo joinInfo,
    required Map<String, String> roster,
  }) {
    _attendees.roster = roster;
    _meeting.isActive = true;
    _attendees.localId = joinInfo.attendeeId;

    _attendees.attendees[joinInfo.attendeeId] = Attendee(
      attendeeId: joinInfo.attendeeId,
      externalUserId: joinInfo.externalUserId,
    );

    listAudioDevices();
    initialAudioSelection();
    notifyListeners();
  }

  Future<void> initialAudioSelection() async {
    try {
      final device = await AmazonChime.instance.initialAudioSelection();
      logger.i('Initial audio device selection: $device');
      _audio.selectedDevice = device;
      notifyListeners();
    } catch (e) {
      logger.e('Failed to get initial audio device: $e');
    }
  }

  Future<void> listAudioDevices() async {
    try {
      final devices = await AmazonChime.instance.listAudioDevices();
      logger.d('Devices available: $devices');
      _audio.deviceList = devices;
      notifyListeners();
    } catch (e) {
      logger.e('Failed to list audio devices: $e');
    }
  }

  Future<void> updateCurrentDevice(String device) async {
    try {
      await AmazonChime.instance.updateAudioDevice(device);
      logger.i('Audio device updated to: $device');
      _audio.selectedDevice = device;
      notifyListeners();
    } catch (e) {
      logger.e('Failed to update audio device to $device: $e');
      rethrow;
    }
  }

  Future<void> sendLocalMuteToggle() async {
    if (!_attendees.attendees.containsKey(_attendees.localId)) return;
    try {
      if (_attendees.attendees[_attendees.localId]!.muteStatus) {
        await AmazonChime.instance.unmute();
      } else {
        await AmazonChime.instance.mute();
      }
    } catch (e) {
      logger.e('Mute toggle failed: $e');
      rethrow;
    }
  }

  Future<void> sendLocalVideoTileOn() async {
    if (!_attendees.attendees.containsKey(_attendees.localId)) return;
    try {
      if (_attendees.attendees[_attendees.localId]!.isVideoOn) {
        await AmazonChime.instance.stopLocalVideo();
      } else {
        await AmazonChime.instance.startLocalVideo();
        await _refreshActiveCameraFacing();
      }
    } catch (e) {
      logger.e('Local video toggle failed: $e');
      rethrow;
    }
  }

  /// Switches between front and back camera and refreshes [activeCameraFacing].
  Future<void> switchCamera() async {
    try {
      await AmazonChime.instance.switchCamera();
      await _refreshActiveCameraFacing();
    } catch (e) {
      logger.e('Camera switch failed: $e');
      rethrow;
    }
  }

  Future<void> sendLocalScreenShareToggle() async {
    try {
      if (isLocalScreenSharing) {
        await AmazonChime.instance.stopScreenShare();
      } else {
        await AmazonChime.instance.startScreenShare();
      }
    } catch (e) {
      logger.e('Screen share toggle failed: $e');
      rethrow;
    }
  }

  Future<void> stopMeeting() async {
    _resetMeetingValues();
    try {
      await AmazonChime.instance.stopMeeting();
    } catch (e) {
      logger.e('Stop meeting failed: $e');
    }
  }

  // ── Private event handlers ─────────────────────────────────────────────────

  void _onAttendeeJoined(Attendee attendee) {
    final id = attendee.attendeeId;
    if (attendee.isContent) {
      logger.i('Content share detected: $id');
      _video.contentAttendeeId = id;
      _attendees.attendees[id] = attendee;
      notifyListeners();
      return;
    }
    if (id != _attendees.localId) {
      _attendees.attendees[id] = attendee;
      logger.i('${attendee.formattedExternalId} has joined the meeting.');
      notifyListeners();
    }
  }

  void _onAttendeeLeftOrDropped(Attendee attendee, {required bool dropped}) {
    final id = attendee.attendeeId;
    if (id == _video.contentAttendeeId) {
      _video.contentAttendeeId = null;
      _video.isReceivingScreenShare = false;
    }
    _attendees.attendees.remove(id);
    _attendees.activeSpeakers.remove(id);
    logger.i('${attendee.formattedExternalId} has ${dropped ? 'dropped from' : 'left'} the meeting.');
    notifyListeners();
  }

  void _changeMuteStatus(Attendee attendee, {required bool mute}) {
    final id = attendee.attendeeId;
    if (_attendees.attendees.containsKey(id)) {
      _attendees.attendees[id] = _attendees.attendees[id]!.copyWith(muteStatus: mute);
      logger.i('${attendee.formattedExternalId} has been ${mute ? 'muted' : 'unmuted'}.');
      notifyListeners();
    }
  }

  void _onVideoTileAdded(VideoTileInfo tile) {
    final id = tile.attendeeId;
    if (tile.isContentShare) {
      _video.isReceivingScreenShare = true;
      final contentId = _video.contentAttendeeId;
      if (contentId != null && _attendees.attendees.containsKey(contentId)) {
        _attendees.attendees[contentId] =
            _attendees.attendees[contentId]!.copyWith(videoTileInfo: tile);
      }
    } else if (_attendees.attendees.containsKey(id)) {
      _attendees.attendees[id] = _attendees.attendees[id]!.copyWith(
        isVideoOn: true,
        videoTileInfo: tile,
      );
    }
    notifyListeners();
  }

  void _onVideoTileRemoved(VideoTileInfo tile) {
    final id = tile.attendeeId;
    if (tile.isContentShare) {
      _video.isReceivingScreenShare = false;
      final contentId = _video.contentAttendeeId;
      if (contentId != null && _attendees.attendees.containsKey(contentId)) {
        _attendees.attendees[contentId] =
            _attendees.attendees[contentId]!.removeVideoTile();
      }
    } else if (_attendees.attendees.containsKey(id)) {
      _attendees.attendees[id] = _attendees.attendees[id]!.removeVideoTile();
    }
    notifyListeners();
  }

  void _onAudioSessionStarted() {
    _meeting.isReconnecting = false;
    logger.i('Audio session started.');
    notifyListeners();
  }

  void _onAudioSessionStopped() {
    logger.i('Audio session stopped.');
    if (!_meeting.isActive) return;
    _resetMeetingValues();
  }

  void _onActiveSpeakersChanged(List<String> ids) {
    _attendees.activeSpeakers = ids;
    notifyListeners();
  }

  void _onConnectionQualityChanged(bool isPoor) {
    _meeting.isConnectionPoor = isPoor;
    logger.i('Connection quality: ${isPoor ? 'poor' : 'recovered'}');
    notifyListeners();
  }

  void _onAudioSessionStartConnecting(bool reconnecting) {
    if (reconnecting) {
      _meeting.isReconnecting = true;
      logger.i('Audio session reconnecting...');
      notifyListeners();
    }
  }

  void _onAudioSessionDropped() {
    _meeting.isReconnecting = true;
    logger.i('Audio session dropped, attempting reconnect.');
    notifyListeners();
  }

  void _onAudioSessionCancelledReconnect() {
    _meeting.isReconnecting = false;
    logger.i('Audio session reconnect cancelled.');
    notifyListeners();
  }

  void _onVideoTilePaused(VideoTileInfo tile) {
    final id = tile.attendeeId;
    if (_attendees.attendees.containsKey(id)) {
      _attendees.attendees[id] = _attendees.attendees[id]!.copyWith(isVideoOn: false);
      notifyListeners();
    }
  }

  void _onVideoTileResumed(VideoTileInfo tile) {
    final id = tile.attendeeId;
    if (_attendees.attendees.containsKey(id)) {
      _attendees.attendees[id] =
          _attendees.attendees[id]!.copyWith(isVideoOn: true, videoTileInfo: tile);
      notifyListeners();
    }
  }

  Future<void> _refreshActiveCameraFacing() async {
    try {
      _video.activeCameraFacing = await AmazonChime.instance.activeCamera();
      notifyListeners();
    } catch (e) {
      logger.e('Failed to refresh active camera: $e');
    }
  }

  void _resetMeetingValues() {
    _meeting.reset();
    _attendees.reset();
    _video.reset();
    _audio.reset();
    logger.i('Meeting values reset.');
    notifyListeners();
  }
}
