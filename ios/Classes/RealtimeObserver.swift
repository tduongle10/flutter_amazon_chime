import AmazonChimeSDK

class ChimeRealtimeObserver: RealtimeObserver {
    let chimeFlutterApi: ChimeFlutterApi

    init(chimeFlutterApi: ChimeFlutterApi) {
        self.chimeFlutterApi = chimeFlutterApi
    }

    func volumeDidChange(volumeUpdates: [VolumeUpdate]) {
        let msgs = volumeUpdates.map { u in
            AttendeeVolumeMsg(attendeeId: u.attendeeInfo.attendeeId,
                              externalUserId: u.attendeeInfo.externalUserId,
                              volume: Int64(u.volumeLevel.rawValue))
        }
        chimeFlutterApi.onAttendeesVolumeChanged(updates: msgs) { _ in }
    }

    func signalStrengthDidChange(signalUpdates: [SignalUpdate]) {
        let msgs = signalUpdates.map { u in
            AttendeeSignalMsg(attendeeId: u.attendeeInfo.attendeeId,
                              externalUserId: u.attendeeInfo.externalUserId,
                              signalStrength: Int64(u.signalStrength.rawValue))
        }
        chimeFlutterApi.onAttendeesSignalChanged(updates: msgs) { _ in }
    }

    func attendeesDidJoin(attendeeInfo: [AttendeeInfo]) {
        for attendee in attendeeInfo {
            let msg = AttendeeMsg(attendeeId: attendee.attendeeId, externalUserId: attendee.externalUserId)
            chimeFlutterApi.onAttendeeJoined(attendee: msg) { _ in }
        }
    }

    func attendeesDidLeave(attendeeInfo: [AttendeeInfo]) {
        for attendee in attendeeInfo {
            let msg = AttendeeMsg(attendeeId: attendee.attendeeId, externalUserId: attendee.externalUserId)
            chimeFlutterApi.onAttendeeLeft(attendee: msg) { _ in }
        }
    }

    func attendeesDidDrop(attendeeInfo: [AttendeeInfo]) {
        for attendee in attendeeInfo {
            let msg = AttendeeMsg(attendeeId: attendee.attendeeId, externalUserId: attendee.externalUserId)
            chimeFlutterApi.onAttendeeDropped(attendee: msg) { _ in }
        }
    }

    func attendeesDidMute(attendeeInfo: [AttendeeInfo]) {
        for attendee in attendeeInfo {
            let msg = AttendeeMsg(attendeeId: attendee.attendeeId, externalUserId: attendee.externalUserId)
            chimeFlutterApi.onAttendeeMuted(attendee: msg) { _ in }
        }
    }

    func attendeesDidUnmute(attendeeInfo: [AttendeeInfo]) {
        for attendee in attendeeInfo {
            let msg = AttendeeMsg(attendeeId: attendee.attendeeId, externalUserId: attendee.externalUserId)
            chimeFlutterApi.onAttendeeUnmuted(attendee: msg) { _ in }
        }
    }
}
