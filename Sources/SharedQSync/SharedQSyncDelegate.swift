//
//  File.swift
//  
//
//  Created by Payton Curry on 4/6/24.
//

import Foundation

public protocol SharedQSyncDelegate {
    /// Called when SharedQSyncManager connects to the group session
    func onGroupConnect()
    /// Called when the server sends an updated SQGroup to the client. This can happen for a variety of reasons. Most commonly, it happens when a song is added to the queue, when someone joins the group, or when an action that changes the group's "currentlyPlaying" is used. RECOMMENDED: Replace the current SQGroup with the new one
    func onGroupUpdate(_ group: SQGroup, _ message: WSMessage)
    /// Called when a client has skipped to the next song in the queue. RECOMMENDED: Start playing the group's "currentlyPlaying" song, as `onGroupUpdate` is called ~2 seconds prior to this, and has the next song in the queue loaded.
    func onNextSong(_ message: WSMessage)
    /// Called when a client has skipped to the previous song in the queue. RECOMMENDED: Start playing the group's "currentlyPlaying" song, as `onGroupUpdate` is called ~2 seconds prior to this, and has the next song in the queue loaded.
    func onPrevSong(_ message: WSMessage)
    /// Called when a client plays the song. This function is not a combined play/pause function because of potential desync issues. If you would like to verify playback state, use the SQGroup's "playbackState" object. RECOMMENDED: Play the group's "currentlyPlaying" song.
    func onPlay(_ message:WSMessage)
    /// Called when a client pauses the song. This function is not a combined play/pause function because of potential desync issues. If you would like to verify playback state, use the SQGroup's "playbackState" object. RECOMMENDED: Pause the song.
    func onPause(_ message: WSMessage)
    /// Called every ~15 seconds as the server sends updated timestamp data to ensure that everybody remains in sync. RECOMMENDED: If the timestamp is more than 2 seconds ahead or behind current playback timestamp, skip to the updated timestamp. Otherwise, do nothing.
    func onTimestampUpdate(_ timestamp: TimeInterval, _ message: WSMessage)
    /// Called when a client seeks to a specific part of a song. RECOMMENDED: Seek to the provided timestamp.
    func onSeekTo(_ timestamp: TimeInterval, _ message: WSMessage)
    /// Called when the client is disconnected from the group
    func onDisconnect()
}
