/// EXPERIMENTAL: This API is not stable and will change without notice
///
/// WCKit simplifies WatchConnectivity communication between iOS and watchOS.
/// This is a prototype package - DO NOT use in production apps.
///
/// - Warning: APIs may break between any version
/// - Version: 0.x (Prototype)

import WatchConnectivity
import os.log

// MARK: - WCKit Main Class
@Observable
public class WCKit: NSObject {
    var store: WCKStore?
    private let logger: Logger
    private var typeMap: [String: any WCKTransferable.Type] = [:]

    public init(store: WCKStore? = nil) {
        self.store = store
        logger = Logger(subsystem: "WCKit", category: "watch-session")
        super.init()
        start()
    }

    // MARK: - Public Methods

    /// Send a WCTransferable object to the paired device
    public func send<T: WCKTransferable>(_ object: T) {
        let typeKey = T.typeKey
        typeMap[typeKey] = T.self

        do {
            let data = try JSONEncoder().encode(object)
            let message =
                [
                    "type": typeKey,
                    "data": data,
                ] as [String: Any]

            guard WCSession.default.isReachable else {
                logger.warning("Watch is not reachable")
                return
            }

            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                self.logger.error("Failed to send message: \(error.localizedDescription)")
            }

            logger.info("Sent message of type: \(typeKey)")
        } catch {
            logger.error("Failed to encode object: \(error)")
        }
    }

    /// Manually register a type for receiving (optional - auto-registers when sending)
    public func register<T: WCKTransferable>(_ type: T.Type) {
        typeMap[T.typeKey] = type
        logger.info("Registered type: \(T.typeKey)")
    }

    /// Check if session is active and reachable
    public var isReachable: Bool {
        return WCSession.default.isReachable
    }

    /// Check session activation state
    public var activationState: WCSessionActivationState {
        return WCSession.default.activationState
    }

    // MARK: - Private Methods

    private func start() {
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity is not supported")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        logger.info("WCKit session activation requested")
    }

    private func handleReceivedData<T: WCKTransferable>(_ data: Data, type: T.Type) throws {
        let decoder = JSONDecoder()
        let object = try decoder.decode(type, from: data)
        try store?.insert(object)
        logger.info("Successfully saved object of type: \(T.typeKey)")
    }
}

// MARK: - WCSessionDelegate
extension WCKit: WCSessionDelegate {

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("Received message")

        guard let typeKey = message["type"] as? String,
            let data = message["data"] as? Data
        else {
            logger.error("Invalid message format - missing type or data")
            return
        }

        guard let registeredType = typeMap[typeKey] else {
            logger.warning(
                "No type registered for key: \(typeKey). Register the type first or send it once to auto-register."
            )
            return
        }

        do {
            // Create a function that works with the existential type
            func decode<T: WCKTransferable>(_ type: T.Type) throws {
                try handleReceivedData(data, type: type)
            }

            // Call with the registered type
            try decode(registeredType)
            logger.info("Successfully processed message of type: \(typeKey)")

        } catch {
            logger.error("Failed to process \(typeKey): \(error.localizedDescription)")
        }
    }

    public func session(
        _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        switch activationState {
        case .activated:
            logger.info("WCSession activated successfully")
        case .inactive:
            logger.info("WCSession inactive")
        case .notActivated:
            logger.warning("WCSession not activated")
        @unknown default:
            logger.error("WCSession unknown activation state")
        }

        if let error = error {
            logger.error("WCSession activation error: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
        public func sessionDidBecomeInactive(_ session: WCSession) {
            logger.info("WCSession became inactive")
        }

        public func sessionDidDeactivate(_ session: WCSession) {
            logger.info("WCSession deactivated")
            // Reactivate the session for iOS
            session.activate()
        }
    #endif  // os(iOS)

    public func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("WCSession reachability changed to: \(session.isReachable)")
    }
}
