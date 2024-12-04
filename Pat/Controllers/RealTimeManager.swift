import Foundation
import SocketIO

class RealTimeManager: ObservableObject {
    static let shared = RealTimeManager()
    @Published var isConnected = false
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var messageId: Int = 0
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
                NSLog("[socket] error:", error)
            }
        }
        
        socket.on("message") { [weak self] data, _ in
            if let message = data.first as? String {
                NSLog("[socket] received message:", message)
                self?.handleMessage(message)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateConnectionState(_ connected: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = connected
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
        
        NSLog("[socket] sending heartbeat:", message)
        socket?.emit("heartbeat", message)
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
                NSLog("[socket] handling emailVerified event")
                try? await AuthState.shared.checkEmailVerification()
            default:
                NSLog("[socket] unhandled event:", event)
            }
        }
    }
}
