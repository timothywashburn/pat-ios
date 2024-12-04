import Foundation
import SocketIO

class RealTimeManager: ObservableObject {
    static let shared = RealTimeManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    @Published var isConnected = false
    private var messageId: Int = 0
    
    func setupWebSocket() {
        guard let token = AuthState.shared.authToken else {
            print("Socket.IO setup skipped: no auth token available")
            return
        }
        
        let baseURL = PatConfig.apiURL.replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        
        // Replace with your custom Socket.IO path if needed
        let socketURL = URL(string: "\(baseURL)/socket.io")!
        
        manager = SocketManager(socketURL: socketURL, config: [
            .log(true),
            .compress,
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .path("/ws") // Custom WebSocket path if required
        ])
        
        socket = manager?.defaultSocket
        
        setupHandlers()
    }
    
    func connect() {
        guard let socket = socket else {
            print("Socket.IO connection skipped: not initialized")
            return
        }
        
        print("Connecting to Socket.IO server...")
        socket.connect()
    }
    
    func disconnect() {
        guard let socket = socket else {
            print("Socket.IO disconnection skipped: not initialized")
            return
        }
        
        print("Disconnecting from Socket.IO server...")
        socket.disconnect()
        isConnected = false
    }
    
    private func setupHandlers() {
        guard let socket = socket else {
            print("Socket.IO handlers setup skipped: not initialized")
            return
        }
        
        // Connection event
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket.IO connected")
            self?.isConnected = true
            
            // Start sending heartbeat every 25 seconds
            Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
        
        // Disconnection event
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("Socket.IO disconnected")
            self?.handleDisconnect()
        }
        
        // Error event
        socket.on(clientEvent: .error) { data, _ in
            if let error = data.first as? String {
                print("Socket.IO error: \(error)")
            }
        }
        
        // Custom message handler
        socket.on("message") { [weak self] data, _ in
            if let message = data.first as? String {
                print("Received message: \(message)")
                self?.handleMessage(message)
            }
        }
    }
    
    private func sendHeartbeat() {
        let heartbeat: [String: Any] = [
            "type": "heartbeat",
            "id": messageId
        ]
        messageId += 1
        
        guard let data = try? JSONSerialization.data(withJSONObject: heartbeat),
              let message = String(data: data, encoding: .utf8) else {
            return
        }
        
        print("Sending heartbeat: \(message)")
        socket?.emit("heartbeat", message)
    }
    
    private func handleDisconnect() {
        print("Handling Socket.IO disconnection...")
        DispatchQueue.main.async {
            self.isConnected = false
            print("Attempting to reconnect in 5 seconds...")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                self.connect()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else {
            return
        }
        
        Task { @MainActor in
            switch event {
            case "emailVerified":
                print("Handling emailVerified event")
                try? await AuthState.shared.checkEmailVerification()
            default:
                print("Unhandled event: \(event)")
            }
        }
    }
}
