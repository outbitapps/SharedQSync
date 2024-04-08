// The Swift Programming Language
// https://docs.swift.org/swift-book


#if !SKIP
import Foundation
import SharedQProtocol

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
    public func connectToGroup(group: SQGroup, user: SQUser) {
        if delegate == nil {
            print("[SharedQSync] [WARNING] No delegate has been provided for this instance of SharedQSyncManager. You will not recieve any messages from the server.")
        }
//        let socketURL = URL(string: "\(baseWSURL)/group/\(self.currentUser!.id)/\(group.id)")!
        let socketURL = websocketURL.appending(path: "/group/\(user.id)/\(group.id)")
        let session = URLSession(configuration: .ephemeral)
        self.socket = session.webSocketTask(with: socketURL)
        socket?.delegate = self
        socket!.resume()
        listenForMessage()
        if let delegate = self.delegate {
            delegate.onGroupConnect(group)
        }
        
    }
    
    private func listenForMessage() {
        socket!.receive { res in
            switch res {
            case .success(let res2):
                switch res2 {
                case .data(let data):
                    let wsMessage = try! JSONDecoder().decode(WSMessage.self, from: data)
                    print(wsMessage.type)
                    switch wsMessage.type {
                    case .groupUpdate:
                        let groupJSON = try! JSONDecoder().decode(SQGroup.self, from: wsMessage.data)
                        if groupJSON.playbackState?.state == .pause {
                            if let delegate = self.delegate {
                                delegate.onPause(wsMessage)
                            }
                        }
                            if let delegate = self.delegate {
                                delegate.onGroupUpdate(groupJSON, wsMessage)
                            }
                    case .timestampUpdate:
                        
                            let timestampUpdateInfo = try! JSONDecoder().decode(WSTimestampUpdate.self, from: wsMessage.data)
                        if let delegate = self.delegate {
                            delegate.onTimestampUpdate(timestampUpdateInfo.timestamp, wsMessage)
                        }
                    case .nextSong:
                        if let delegate = self.delegate {
                            delegate.onNextSong(wsMessage)
                        }
                    case .goBack:
                        if let delegate = self.delegate {
                            delegate.onPrevSong(wsMessage)
                        }
                    case .play:
                        if let delegate = self.delegate {
                            delegate.onPlay(wsMessage)
                        }
                    case .pause:
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
            case .failure(let failure):
                print("[SharedQSyncManager] websocket data failed: \(failure) (if this is only happening occasionally, you can probably ignore it)")
                
            }
            if self.socket!.state == .running {
                self.listenForMessage()
            }
        }
    }
    /// Sends a `pauseSong` message to the server
    public func pauseSong() async throws {
        if let socket = socket {
            
            let jsonData = try JSONEncoder().encode(WSMessage(type: .pause, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    /// Sends a `playSong` message to the server
    public func playSong() async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .play, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
            try await socket.send(.data(jsonData))
        }
    }
    /// Sends a `nextSong` message to the server
    public func nextSong() async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .nextSong, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    /// Adds the SQSong to the queue
    public func addToQueue(song: SQSong, user: SQUser) async throws {
        if let socket = socket {
            let jsonData = try JSONEncoder().encode(WSMessage(type: .addToQueue, data: try! JSONEncoder().encode(SQQueueItem(song: song, addedBy: user.username)), sentAt: Date()))
                try await socket.send(.data(jsonData))
        }
    }
    public func disconnect() async {
        if let socket = socket {
            socket.cancel(with: .normalClosure, reason: nil)
        }
    }
    
    public func playbackStarted() async throws {
        try await socket?.send(.data(try! JSONEncoder().encode(WSMessage(type: .playbackStarted, data: try JSONEncoder().encode(WSPlaybackStartedMessage(startedAt: Date())), sentAt: Date()))))
    }
}

extension SharedQSyncManager: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("closed: \(closeCode) \(String(data: reason ?? Data(), encoding: .utf8))")
        if let delegate = self.delegate {
            delegate.onDisconnect()
        }
    }
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        print("ERROR: \(error)")
    }
}
#endif
