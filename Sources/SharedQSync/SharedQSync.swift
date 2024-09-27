// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SharedQProtocol
import OSLog

let logger: Logger = Logger(subsystem: "com.paytondeveloper.sharedqandroid", category: "SharedQSync")

public class SharedQSyncManager : NSObject {
    public var delegate: SharedQSyncDelegate?
    public var serverURL: URL
    public var websocketURL: URL
    var socket: URLSessionWebSocketTask?
    public init(serverURL: URL = URL(string: "http://sq.paytondev.cloud:8080")!, websocketURL: URL = URL(string: "ws://sq.paytondev.cloud:8080")!) {
        self.serverURL = serverURL
        self.websocketURL = websocketURL
    }
    /// Creates a WebSocket session with the server (uses websocketURL from `init`)
    public func connectToGroup(group: SQGroup, token: String) async {
        do {
            if delegate == nil {
                logger.warning("[SharedQSync] [WARNING] No delegate has been provided for this instance of SharedQSyncManager. You will not recieve any messages from the server.")
            }
            let tokenURL = URL(string: "\(serverURL.absoluteString)/groups/getws/\(group.id)")!
            var request = URLRequest(url: tokenURL)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            let (data, _) = try await URLSession.shared.data(for: request)
            let wsToken = String(data: data, encoding: .utf8)
            let socketURL = URL(string: "\(websocketURL.absoluteString)/groups/connect/\(wsToken)")!
    //        let socketURL = websocketURL.appending(path: "/groups/group/\(group.id)/\(token)")
            
            let session = URLSession(configuration: .ephemeral)
            
            self.socket = session.webSocketTask(with: socketURL)
            
            socket?.delegate = self
            socket!.resume()
            listenForMessage()
            if let delegate = self.delegate {
                delegate.onGroupConnect(group)
            }
        } catch {
            logger.error("There was an error connecting to the group: \(error.localizedDescription)")
            return
        }
         
    }
    
    private func listenForMessage() {
        Task {
            do {
                let res = try await (socket as URLSessionWebSocketTask?)!.receive()
                switch res as! URLSessionWebSocketTask.Message {
                case .data(let data):
                    let wsMessage = try! JSONDecoder().decode(WSMessage.self, from: data)
                    logger.log("new wsmessage")
                    switch wsMessage.type {
                    case WSMessageType.groupUpdate:
                        let groupJSON = try! JSONDecoder().decode(SQGroup.self, from: wsMessage.data.data(using: .utf8) ?? Data())
                        if groupJSON.playbackState?.state == PlayPauseState.pause {
                            if let delegate = self.delegate {
                                delegate.onPause(wsMessage)
                            }
                        }
                            if let delegate = self.delegate {
                                delegate.onGroupUpdate(groupJSON, wsMessage)
                            }
                    case WSMessageType.timestampUpdate:
                        
                        let timestampUpdateInfo = try! JSONDecoder().decode(WSTimestampUpdate.self, from: wsMessage.data.data(using: .utf8) ?? Data())
                        if let delegate = self.delegate {
                            delegate.onTimestampUpdate(timestampUpdateInfo.timestamp, wsMessage)
                        }
                    case WSMessageType.nextSong:
                        if let delegate = self.delegate {
                            delegate.onNextSong(wsMessage)
                        }
                    case WSMessageType.goBack:
                        if let delegate = self.delegate {
                            delegate.onPrevSong(wsMessage)
                        }
                    case WSMessageType.play:
                        if let delegate = self.delegate {
                            delegate.onPlay(wsMessage)
                        }
                    case WSMessageType.pause:
                        if let delegate = self.delegate {
                            delegate.onPause(wsMessage)
                        }
                    default:
                        break;
                    }
                    break;
                case .string(let string):
                    break;
                }
                if self.socket!.state == .running {
                    self.listenForMessage()
                }
            } catch {
                logger.error("Error getting data from websocket: \(error)")
            }
        }
    }
    /// Sends a `pauseSong` message to the server
    public func pauseSong() async throws {
        if let socket = socket {
            
            let jsonData = try JSONEncoder().encode(WSMessage(type: .pause, data: "", sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    /// Sends a `playSong` message to the server
    public func playSong() async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .play, data: "", sentAt: Date()))
            try await socket.send(.data(jsonData))
        }
    }
    /// Sends a `nextSong` message to the server
    public func nextSong() async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .nextSong, data: "", sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    /// Adds the SQSong to the queue
    public func addToQueue(song: SQSong, user: SQUser) async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .addToQueue, data: String(data: try! JSONEncoder().encode(SQQueueItem(song: song, addedBy: user.username)), encoding: .utf8) ?? "", sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    public func disconnect() async {
        if let socket = socket {
            socket.cancel(with: .normalClosure, reason: nil)
        }
    }
    
    public func playbackStarted() async throws {
        try await socket?.send(.data(try! JSONEncoder().encode(WSMessage(type: .playbackStarted, data: String(data: try JSONEncoder().encode(WSPlaybackStartedMessage(startedAt: Date())), encoding: .utf8) ?? "", sentAt: Date()))))
    }
}

extension SharedQSyncManager: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        logger.debug("closed: \(closeCode.rawValue)")
        if let delegate = self.delegate {
            delegate.onDisconnect()
        }
    }
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        logger.error("ERROR: \(error)")
    }
}
