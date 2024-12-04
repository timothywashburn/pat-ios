import Foundation
import SocketIO

struct SocketMessage<T: Codable>: Codable {
    let type: String
    let userId: String
    let data: T
}

struct EmptyData: Codable {}

class SocketService: ObservableObject {
    static let shared = SocketService()
    @Published var isConnected = false
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var reconnectTimer: Timer?
    
    // MARK: - Public Methods
    
    func connect() {
        if socket == nil {
            setupWebSocket()
        }
        
        guard let socket = socket else {
            NSLog("[socket] connection skipped: not initialized")
            return
        }
        if socket.status == .connected {
            NSLog("[socket] already connected")
            return
        }
        
        NSLog("[socket] connecting...")
        socket.connect()
    }
    
    func disconnect() {
        guard let socket = socket else {
            NSLog("[socket] disconnection skipped: not initialized")
            return
        }
        NSLog("[socket] disconnecting...")
        socket.disconnect()
        isConnected = false
    }
    
    // MARK: - Private Setup
    
    private func setupWebSocket() {
        guard let token = AuthState.shared.authToken else {
            NSLog("[socket] setup skipped: no auth token")
            return
        }
        
        disconnect()
        
        let baseURL = PatConfig.apiURL
        let socketURL = URL(string: baseURL)!
        
        var urlComponents = URLComponents(url: socketURL, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "token", value: token)]
        
        NSLog("[socket] initializing with url: \(baseURL)")
        
        manager = SocketManager(socketURL: socketURL, config: [
            .compress,
            .connectParams(["token": token]),
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .path("/ws"),
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(5000)
        ])
        
        socket = manager?.defaultSocket
        setupHandlers()
    }
    
    private func setupHandlers() {
        guard let socket = socket else {
            NSLog("[socket] handlers setup skipped: not initialized")
            return
        }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            NSLog("[socket] connected")
            self?.updateConnectionState(true)
            
            self?.reconnectTimer?.invalidate()
            self?.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            NSLog("[socket] disconnected")
            self?.updateConnectionState(false)
        }
        
        socket.on(clientEvent: .error) { data, _ in
            if let error = data.first as? String {
                NSLog("[socket] error: \(error)")
            }
        }
        
        socket.on("message") { [weak self] data, _ in
            guard let messageData = data.first else {
                NSLog("[socket] received empty message")
                return
            }
            
            NSLog("[socket] received message: \(messageData)")
            self?.handleIncomingMessage(messageData)
        }
    }
    
    private func handleIncomingMessage(_ messageData: Any) {
        guard let dict = messageData as? [String: Any],
              let type = dict["type"] as? String else {
            NSLog("[socket] malformed message: \(messageData)")
            return
        }
        
        NSLog("[socket] handling message type: \(type)")
        
        Task { @MainActor in
            switch type {
            case "emailVerified":
                if let data = try? JSONSerialization.data(withJSONObject: dict),
                   let message = try? JSONDecoder().decode(SocketMessage<EmptyData>.self, from: data) {
                    NSLog("[socket] handling emailVerified for user: \(message.userId)")
                    AuthState.shared.updateUserInfo { user in
                        user.isEmailVerified = true
                    }
                }
                
            default:
                NSLog("[socket] unhandled message type: \(type)")
            }
        }
    }
    
    // MARK: - Heartbeat
    
    private func updateConnectionState(_ connected: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = connected
        }
    }
    
    private func sendHeartbeat() {
        let heartbeat = SocketMessage(
            type: "heartbeat",
            userId: "",
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        
        guard let data = try? JSONEncoder().encode(heartbeat),
              let message = String(data: data, encoding: .utf8) else {
            return
        }
        
        NSLog("[socket] sending heartbeat: \(message)")
        socket?.emit("heartbeat", message)
    }
}
