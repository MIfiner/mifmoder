import Foundation
import UIKit
import SwiftSignalKit

public final class LightGramGhostController {
    public static let shared = LightGramGhostController()
    
    // Set of peer IDs temporarily exempt from suppression (e.g., if user manually taps 'Mark as read')
    private var manuallyReadPeers = Set<Int64>()
    private let lock = NSLock()
    
    public init() {}
    
    public func shouldSuppressReadHistory(peerId: Int64) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.manuallyReadPeers.contains(peerId) {
            return false
        }
        return LightGramSettings.shared.suppressReadHistory
    }
    
    public func markPeerAsReadManually(peerId: Int64) {
        self.lock.lock()
        self.manuallyReadPeers.insert(peerId)
        self.lock.unlock()
    }
    
    public func resetManualRead(peerId: Int64) {
        self.lock.lock()
        self.manuallyReadPeers.remove(peerId)
        self.lock.unlock()
    }
    
    public func shouldSuppressTyping(peerId: Int64) -> Bool {
        return LightGramSettings.shared.suppressTyping
    }
    
    public func shouldSuppressStoryView() -> Bool {
        return LightGramSettings.shared.suppressStoryViews
    }
}
