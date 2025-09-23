/// EXPERIMENTAL: This API is not stable and will change without notice
///
/// WCKit simplifies WatchConnectivity communication between iOS and watchOS.
/// This is a prototype package - DO NOT use in production apps.
///
/// - Warning: APIs may break between any version
/// - Version: 0.x (Prototype)

import WatchConnectivity
import OSLog

final class WCKService: NSObject, WCSessionDelegate {
    private let logger = Logger(subsystem: "WCKit", category: "watch-session")

    var isReachable: Bool { WCSession.default.isReachable }
    var activationState: WCSessionActivationState { WCSession.default.activationState }
    var onIncomingData: ((Data) -> Void)?

    override init() {
        super.init()
        start()
    }

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

    // Immediate message + reply path (both sides must be reachable)
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        logger.info("didReceiveMessageData: \(messageData.count) bytes")

    #if os(iOS)
        onIncomingData?(messageData)
    #endif
        // IMPORTANT: call replyHandler exactly once and quickly
        replyHandler(Data())
    }

    // Activation lifecycle
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        switch activationState {
            case .activated:
                logger.info("WCSession activated")
            case .inactive:
                logger.info("WCSession inactive")
            case .notActivated:
                logger.warning("WCSession not activated")
            @unknown default:
                logger.error("WCSession unknown activation state")
        }
        if let error { logger.error("WCSession activation error: \(error.localizedDescription)") }
    }

    // iOS-only lifecycle
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession became inactive (iOS)")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession deactivated (iOS) — reactivating")
        session.activate()
    }
    #endif

    // Helpful for debugging reachability flips
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Reachability changed: \(self.isReachable, privacy: .public)")
    }

    // OPTIONAL: background-friendly channels
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        logger.info("didReceiveApplicationContext: \(applicationContext.keys.joined(separator: ","), privacy: .public)")
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        logger.info("didReceiveUserInfo: \(userInfo.keys.joined(separator: ","), privacy: .public)")
    }
}
