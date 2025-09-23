/// EXPERIMENTAL: This API is not stable and will change without notice
///
/// WCKit simplifies WatchConnectivity communication between iOS and watchOS.
/// This is a prototype package - DO NOT use in production apps.
///
/// - Warning: APIs may break between any version
/// - Version: 0.x (Prototype)

import WatchConnectivity
import SwiftData
import OSLog

@Observable
public class WCKit<T: Codable & PersistentModel>: NSObject {
    let modelType: T.Type
    let context: ModelContext?
    private let logger: Logger
    private let wckService: WCKService
    
    public init(modelType: T.Type, context: ModelContext? = nil) {
        self.modelType = modelType
        self.context = context
        self.logger = Logger(subsystem: "WCKit", category: "watch-session")
        self.wckService = WCKService()
        super.init()

        wckService.onIncomingData = { [weak self] data in
            guard let self = self else { return }
            #if os(iOS)
            self.saveData(data)
            #endif
        }
    }
    
    public func sendData(_ object: T) {
        do {
            let data = try JSONEncoder().encode(object)
            guard wckService.isReachable else {
                logger.warning("Counterpart not reachable — consider transferUserInfo/updateApplicationContext")
                return
            }
            WCSession.default.sendMessageData(
                data,
                replyHandler: { _ in
                    self.logger.info("ACK received")
                },
                errorHandler: { err in
                    self.logger.error("sendMessageData error: \(err.localizedDescription)")
                }
            )
        } catch {
            logger.error("Failed to encode object: \(error.localizedDescription)")
        }
    }
    
    
    private func saveData(_ data: Data) {
        do {
            let decodedObject = try JSONDecoder().decode(modelType, from: data)
            guard let context else { return }
            context.insert(decodedObject)
            try context.save()
            logger.info("Saved \(String(describing: self.modelType)) to SwiftData")
        } catch {
            logger.error("Decode/save failed: \(error.localizedDescription)")
        }
    }
}
