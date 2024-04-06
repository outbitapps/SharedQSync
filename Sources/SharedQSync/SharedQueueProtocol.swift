import Foundation

public struct SQGroup: Identifiable, Codable {
    /// The ID of the group
    public var id: String
    /// The name of the group
    public var name: String
    /// The owner of thr group
    public var owner: SQUser
    /// The default permissions of the group
    public var defaultPermissions: SQDefaultPermissions
    /// The members of the group (and their specific permissions)
    public var members: [SQUserPermissions] = []
    /// The `id`'s of users currently in a live listening session
    public var connectedMembers: [String] = []
    /// Whether or not the group is public
    public var publicGroup: Bool
    /// Whether or not askToJoin is enabled
    public var askToJoin: Bool
    /// (unused) The websocket URL of the server (please use `SharedQSyncManager.connectToGroup` instead!)
    public var wsURL: URL?
    /// The currently playing song
    public var currentlyPlaying: SQSong?
    /// The group's queue
    public var previewQueue: [SQQueueItem] = []
    /// The group's playback state
    public var playbackState: SQPlaybackState?
    /// (unused by client) the URL used to join the group
    public var groupURL: URL?
    /// The `id`'s of users attempting to join the group (if ask to join is enabled)
    public var joinRequests: [String] = []
}
public struct SQPlaybackState: Identifiable, Codable {
    public var id: UUID = UUID()
    /// The play/pause state of the currently playing song
    public var state: PlayPauseState
    /// The current timestamp of the currently playing song (note: do not use this for timestamp updates, use `SharedQSyncDelegate.onTimestampUpdate` instead. this should be used for displaying the timestamp to the user)
    public var timestamp: TimeInterval
}

public enum PlayPauseState: Codable {
    /// The song is playing
    case play
    /// The song is paused
    case pause
}

public struct SQSong: Identifiable, Codable {
    public var id: String = UUID().uuidString
    /// The title of the song
    public var title: String
    /// The name of the artist(s)
    public var artist: String
    /// A URL to the album art (512x512)
    public var albumArt: URL? = nil
    /// The primary colors in the albumArt. Typically has a count of 2.
    public var colors: [String] = []
    /// (unused)
    public var textColor: String? = nil
    /// The duration of the song
    public var duration: TimeInterval
}

public struct SQDefaultPermissions: Codable, Identifiable {
    public var id: String
    /// Controls whether or not members can control playback (play/pause, skip, seek)
    public var membersCanControlPlayback: Bool
    /// Controls whether or not members can add songs to queue
    public var membersCanAddToQueue: Bool
}

public struct SQUser: Identifiable, Codable {
    /// The user's FirebaseAuth UID
    public var id: String
    /// The user's username
    public var username: String
    /// The user's email (if they signed up using an email address(
    public var email: String?
    /// The `id`s of groups the user is a member of
    public var groups: [String]
}

public struct SQQueueItem: Identifiable, Codable {
    public var id = UUID().uuidString
    /// The song
    public var song: SQSong
    /// The username of who added the song
    public var addedBy: String
}

public struct SQUserPermissions: Codable, Identifiable {
    public var id: String
    /// The user
    public var user: SQUser
    /// Whether or not the user can control playback
    public var canControlPlayback: Bool
    /// Whether or not the user can add to queue
    public var canAddToQueue: Bool
    /// The last time the user joined a live listening session
    public var lastConnected: Date?
}

public struct JoinGroupRequest: Codable {
    public var myUID: String
    public var groupID: String
}

public struct WSMessage: Codable {
    /// The specific message
    public var type: WSMessageType
    /// The data associated with the message
    public var data: Data
    /// The date the message was sent. Use this to ensure a perfect sync
    public var sentAt: Date
}

public enum WSMessageType: Codable {
    /// The server is sending a group update
    case groupUpdate
    /// A user has skipped this song
    case nextSong
    /// A user has gone back in queue
    case goBack
    /// A user has played the song
    case play
    /// A user has paused the song
    case pause
    /// The server is sending an updated timestamp
    case timestampUpdate
    /// (unused)
    case playbackStarted
    /// A user has seeked to a specific part of the song
    case seekTo
    /// (sent by client) Client is trying to add a song to the queue
    case addToQueue
}


public struct WSPlaybackStartedMessage: Codable {
    public var startedAt: Date
}
public struct WSTimestampUpdate: Codable {
    public var timestamp: TimeInterval
    public var sentAt: Date
}
