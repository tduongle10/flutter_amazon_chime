import 'dart:async';
import 'package:flutter_amazon_chime/models/models.dart';
import 'package:flutter_amazon_chime/logger.dart';
import 'package:flutter_amazon_chime/src/chime_api.dart';

class MethodChannelCoordinator implements ChimeFlutterApi {
  static final MethodChannelCoordinator instance = MethodChannelCoordinator._();

  final ChimeHostApi hostApi = ChimeHostApi();

  MethodChannelCoordinator._() {
    ChimeFlutterApi.setUp(this);
    logger.i('Pigeon Flutter API Handler initialized.');
  }

  final _attendeeJoinController = StreamController<Attendee>.broadcast();
  final _attendeeLeaveController = StreamController<Attendee>.broadcast();
  final _attendeeDropController = StreamController<Attendee>.broadcast();
  final _attendeeMuteController = StreamController<Attendee>.broadcast();
  final _attendeeUnmuteController = StreamController<Attendee>.broadcast();
  final _videoTileAddController = StreamController<VideoTileInfo>.broadcast();
  final _videoTileRemoveController = StreamController<VideoTileInfo>.broadcast();
  final _audioSessionStartController = StreamController<void>.broadcast();
  final _audioSessionStopController = StreamController<void>.broadcast();
  final _audioSessionStartConnectingController = StreamController<bool>.broadcast();
  final _audioSessionDroppedController = StreamController<void>.broadcast();
  final _audioSessionCancelledReconnectController = StreamController<void>.broadcast();
  final _connectionQualityChangedController = StreamController<bool>.broadcast();
  final _activeSpeakersChangedController = StreamController<List<String>>.broadcast();
  final _videoTilePausedController = StreamController<VideoTileInfo>.broadcast();
  final _videoTileResumedController = StreamController<VideoTileInfo>.broadcast();
  final _contentShareStateChangedController = StreamController<int>.broadcast();
  final _attendeesVolumeChangedController = StreamController<List<AttendeeVolume>>.broadcast();
  final _attendeesSignalChangedController = StreamController<List<AttendeeSignal>>.broadcast();
  final _dataMessageReceivedController = StreamController<DataMessage>.broadcast();
  final _remoteVideoSourcesAvailableController = StreamController<List<RemoteVideoSource>>.broadcast();
  final _remoteVideoSourcesUnavailableController = StreamController<List<RemoteVideoSource>>.broadcast();
  final _meetingMetricsReceivedController = StreamController<Map<String, Object?>>.broadcast();
  final _meetingEventReceivedController = StreamController<MeetingEvent>.broadcast();

  Stream<Attendee> get attendeeJoinedStream => _attendeeJoinController.stream;
  Stream<Attendee> get attendeeLeftStream => _attendeeLeaveController.stream;
  Stream<Attendee> get attendeeDroppedStream => _attendeeDropController.stream;
  Stream<Attendee> get attendeeMutedStream => _attendeeMuteController.stream;
  Stream<Attendee> get attendeeUnmutedStream => _attendeeUnmuteController.stream;
  Stream<VideoTileInfo> get videoTileAddedStream => _videoTileAddController.stream;
  Stream<VideoTileInfo> get videoTileRemovedStream => _videoTileRemoveController.stream;
  Stream<void> get audioSessionStartedStream => _audioSessionStartController.stream;
  Stream<void> get audioSessionStoppedStream => _audioSessionStopController.stream;
  Stream<bool> get audioSessionStartConnectingStream => _audioSessionStartConnectingController.stream;
  Stream<void> get audioSessionDroppedStream => _audioSessionDroppedController.stream;
  Stream<void> get audioSessionCancelledReconnectStream => _audioSessionCancelledReconnectController.stream;
  Stream<bool> get connectionQualityChangedStream => _connectionQualityChangedController.stream;
  Stream<List<String>> get activeSpeakersChangedStream => _activeSpeakersChangedController.stream;
  Stream<VideoTileInfo> get videoTilePausedStream => _videoTilePausedController.stream;
  Stream<VideoTileInfo> get videoTileResumedStream => _videoTileResumedController.stream;
  Stream<int> get contentShareStateChangedStream => _contentShareStateChangedController.stream;
  Stream<List<AttendeeVolume>> get attendeesVolumeChangedStream => _attendeesVolumeChangedController.stream;
  Stream<List<AttendeeSignal>> get attendeesSignalChangedStream => _attendeesSignalChangedController.stream;
  Stream<DataMessage> get dataMessageReceivedStream => _dataMessageReceivedController.stream;
  Stream<List<RemoteVideoSource>> get remoteVideoSourcesAvailableStream => _remoteVideoSourcesAvailableController.stream;
  Stream<List<RemoteVideoSource>> get remoteVideoSourcesUnavailableStream => _remoteVideoSourcesUnavailableController.stream;
  Stream<Map<String, Object?>> get meetingMetricsReceivedStream => _meetingMetricsReceivedController.stream;
  Stream<MeetingEvent> get meetingEventReceivedStream => _meetingEventReceivedController.stream;

  @override
  void onAttendeeJoined(AttendeeMsg attendee) {
    _attendeeJoinController.add(Attendee(attendeeId: attendee.attendeeId!, externalUserId: attendee.externalUserId!));
  }

  @override
  void onAttendeeLeft(AttendeeMsg attendee) {
    _attendeeLeaveController.add(Attendee(attendeeId: attendee.attendeeId!, externalUserId: attendee.externalUserId!));
  }

  @override
  void onAttendeeDropped(AttendeeMsg attendee) {
    _attendeeDropController.add(Attendee(attendeeId: attendee.attendeeId!, externalUserId: attendee.externalUserId!));
  }

  @override
  void onAttendeeMuted(AttendeeMsg attendee) {
    _attendeeMuteController.add(Attendee(attendeeId: attendee.attendeeId!, externalUserId: attendee.externalUserId!));
  }

  @override
  void onAttendeeUnmuted(AttendeeMsg attendee) {
    _attendeeUnmuteController.add(Attendee(attendeeId: attendee.attendeeId!, externalUserId: attendee.externalUserId!));
  }

  @override
  void onVideoTileAdded(VideoTileMsg tile) {
    _videoTileAddController.add(VideoTileInfo(
      tileId: tile.tileId!,
      attendeeId: tile.attendeeId!,
      videoStreamContentHeight: tile.videoStreamContentHeight!,
      videoStreamContentWidth: tile.videoStreamContentWidth!,
      isLocalTile: tile.isLocalTile!,
      isContentShare: tile.attendeeId?.contains('#content') ?? false,
    ));
  }

  @override
  void onVideoTileRemoved(VideoTileMsg tile) {
    _videoTileRemoveController.add(VideoTileInfo(
      tileId: tile.tileId!,
      attendeeId: tile.attendeeId!,
      videoStreamContentHeight: tile.videoStreamContentHeight!,
      videoStreamContentWidth: tile.videoStreamContentWidth!,
      isLocalTile: tile.isLocalTile!,
      isContentShare: tile.attendeeId?.contains('#content') ?? false,
    ));
  }

  @override
  void onAudioSessionStarted() {
    _audioSessionStartController.add(null);
  }

  @override
  void onAudioSessionStopped() {
    _audioSessionStopController.add(null);
  }

  @override
  void onAudioSessionStartConnecting(bool reconnecting) {
    _audioSessionStartConnectingController.add(reconnecting);
  }

  @override
  void onAudioSessionDropped() {
    _audioSessionDroppedController.add(null);
  }

  @override
  void onAudioSessionCancelledReconnect() {
    _audioSessionCancelledReconnectController.add(null);
  }

  @override
  void onConnectionQualityChanged(bool isPoor) {
    _connectionQualityChangedController.add(isPoor);
  }

  @override
  void onActiveSpeakersChanged(List<String?> attendeeIds) {
    _activeSpeakersChangedController.add(attendeeIds.whereType<String>().toList());
  }

  @override
  void onVideoTilePaused(VideoTileMsg tile) {
    _videoTilePausedController.add(VideoTileInfo(
      tileId: tile.tileId!,
      attendeeId: tile.attendeeId!,
      videoStreamContentHeight: tile.videoStreamContentHeight!,
      videoStreamContentWidth: tile.videoStreamContentWidth!,
      isLocalTile: tile.isLocalTile!,
      isContentShare: tile.attendeeId?.contains('#content') ?? false,
    ));
  }

  @override
  void onVideoTileResumed(VideoTileMsg tile) {
    _videoTileResumedController.add(VideoTileInfo(
      tileId: tile.tileId!,
      attendeeId: tile.attendeeId!,
      videoStreamContentHeight: tile.videoStreamContentHeight!,
      videoStreamContentWidth: tile.videoStreamContentWidth!,
      isLocalTile: tile.isLocalTile!,
      isContentShare: tile.attendeeId?.contains('#content') ?? false,
    ));
  }

  @override
  void onContentShareStateChanged(int state) {
    _contentShareStateChangedController.add(state);
  }

  @override
  void onAttendeesVolumeChanged(List<AttendeeVolumeMsg> updates) {
    final list = updates.map((u) => AttendeeVolume(
      attendeeId: u.attendeeId!,
      externalUserId: u.externalUserId!,
      volume: u.volume!.toInt(),
    )).toList();
    _attendeesVolumeChangedController.add(list);
  }

  @override
  void onAttendeesSignalChanged(List<AttendeeSignalMsg> updates) {
    final list = updates.map((u) => AttendeeSignal(
      attendeeId: u.attendeeId!,
      externalUserId: u.externalUserId!,
      signalStrength: u.signalStrength!.toInt(),
    )).toList();
    _attendeesSignalChangedController.add(list);
  }

  @override
  void onDataMessageReceived(DataMessageMsg message) {
    _dataMessageReceivedController.add(DataMessage(
      topic: message.topic ?? '',
      data: message.data ?? '',
      senderAttendeeId: message.senderAttendeeId ?? '',
      senderExternalUserId: message.senderExternalUserId ?? '',
      timestampMs: message.timestampMs ?? 0,
      throttled: message.throttled ?? false,
    ));
  }

  @override
  void onRemoteVideoSourcesAvailable(List<RemoteVideoSourceMsg?> sources) {
    final list = sources.whereType<RemoteVideoSourceMsg>().map((s) => RemoteVideoSource(attendeeId: s.attendeeId ?? '')).toList();
    _remoteVideoSourcesAvailableController.add(list);
  }

  @override
  void onRemoteVideoSourcesUnavailable(List<RemoteVideoSourceMsg?> sources) {
    final list = sources.whereType<RemoteVideoSourceMsg>().map((s) => RemoteVideoSource(attendeeId: s.attendeeId ?? '')).toList();
    _remoteVideoSourcesUnavailableController.add(list);
  }

  @override
  void onMeetingMetricsReceived(Map<String?, Object?> metrics) {
    _meetingMetricsReceivedController.add(Map<String, Object?>.fromEntries(
      metrics.entries.where((e) => e.key != null).map((e) => MapEntry(e.key!, e.value)),
    ));
  }

  @override
  void onMeetingEventReceived(String name, Map<String?, Object?> attributes) {
    final attrs = Map<String, Object?>.fromEntries(
      attributes.entries.where((e) => e.key != null).map((e) => MapEntry(e.key!, e.value)),
    );
    _meetingEventReceivedController.add(MeetingEvent(name: name, attributes: attrs));
  }
}
