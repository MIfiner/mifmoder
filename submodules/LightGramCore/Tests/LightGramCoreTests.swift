import XCTest
@testable import LightGramCore

final class LightGramCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset defaults for predictable testing
        LightGramSettings.shared.isGhostModeEnabled = false
        LightGramSettings.shared.suppressReadHistory = false
        LightGramSettings.shared.suppressTyping = false
        LightGramSettings.shared.suppressStoryViews = false
        LightGramSettings.shared.isSpyModeEnabled = true
        LightGramSettings.shared.saveDeletedMessages = true
        LightGramSettings.shared.saveEditHistory = true
        LightGramSettings.shared.retentionDaysTTL = 30
    }
    
    func testLightGramSettingsDefaults() {
        let settings = LightGramSettings.shared
        XCTAssertFalse(settings.isGhostModeEnabled)
        XCTAssertFalse(settings.suppressReadHistory)
        XCTAssertFalse(settings.suppressTyping)
        XCTAssertFalse(settings.suppressStoryViews)
        XCTAssertTrue(settings.isSpyModeEnabled)
        XCTAssertTrue(settings.saveDeletedMessages)
        XCTAssertTrue(settings.saveEditHistory)
        XCTAssertEqual(settings.retentionDaysTTL, 30)
        XCTAssertTrue(settings.smartFiltersEnabled)
    }
    
    func testLightGramSettingsPersistence() {
        let settings = LightGramSettings.shared
        
        settings.isGhostModeEnabled = true
        settings.suppressReadHistory = true
        settings.suppressTyping = true
        
        XCTAssertTrue(settings.isGhostModeEnabled)
        XCTAssertTrue(settings.suppressReadHistory)
        XCTAssertTrue(settings.suppressTyping)
        
        // Turn off master ghost mode - child toggles should evaluate to false
        settings.isGhostModeEnabled = false
        XCTAssertFalse(settings.suppressReadHistory)
        XCTAssertFalse(settings.suppressTyping)
    }
    
    func testGhostControllerSuppression() {
        let ghost = LightGramGhostController.shared
        let peerId: Int64 = 123456789
        
        LightGramSettings.shared.isGhostModeEnabled = false
        XCTAssertFalse(ghost.shouldSuppressReadHistory(peerId: peerId))
        XCTAssertFalse(ghost.shouldSuppressTyping(peerId: peerId))
        
        LightGramSettings.shared.isGhostModeEnabled = true
        LightGramSettings.shared.suppressReadHistory = true
        LightGramSettings.shared.suppressTyping = true
        LightGramSettings.shared.suppressStoryViews = true
        
        XCTAssertTrue(ghost.shouldSuppressReadHistory(peerId: peerId))
        XCTAssertTrue(ghost.shouldSuppressTyping(peerId: peerId))
        XCTAssertTrue(ghost.shouldSuppressStoryView())
        
        // Test manual read override
        ghost.markPeerAsReadManually(peerId: peerId)
        XCTAssertFalse(ghost.shouldSuppressReadHistory(peerId: peerId))
        
        ghost.resetManualRead(peerId: peerId)
        XCTAssertTrue(ghost.shouldSuppressReadHistory(peerId: peerId))
    }
    
    func testSpyManagerDeletedMessages() {
        let spy = LightGramSpyManager.shared
        let expectation = self.expectation(description: "Fetch deleted")
        
        let testPeerId: Int64 = 998877
        let testMsgId: Int32 = 42
        let testText = "Secret message that got deleted"
        let testAuthor = "Alice"
        let timestamp = Int32(Date().timeIntervalSince1970)
        
        spy.recordDeletedMessage(
            peerId: testPeerId,
            messageId: testMsgId,
            authorName: testAuthor,
            text: testText,
            mediaType: nil,
            originalTimestamp: timestamp
        )
        
        // Give background dispatch time to persist
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            spy.fetchDeletedMessages(peerId: testPeerId) { records in
                XCTAssertFalse(records.isEmpty)
                let record = records.first(where: { $0.messageId == testMsgId })
                XCTAssertNotNil(record)
                XCTAssertEqual(record?.text, testText)
                XCTAssertEqual(record?.authorName, testAuthor)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSpyManagerEditHistory() {
        let spy = LightGramSpyManager.shared
        let expectation = self.expectation(description: "Fetch edits")
        
        let testPeerId: Int64 = 887766
        let testMsgId: Int32 = 101
        let originalText = "Original sentence before typo fix"
        let editedText = "Corrected sentence after typo fix"
        
        spy.recordEditedMessage(
            peerId: testPeerId,
            messageId: testMsgId,
            authorName: "Bob",
            previousText: originalText,
            newText: editedText
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            spy.fetchEditHistory(peerId: testPeerId, messageId: testMsgId) { records in
                XCTAssertFalse(records.isEmpty)
                let record = records.first
                XCTAssertEqual(record?.previousText, originalText)
                XCTAssertEqual(record?.newText, editedText)
                XCTAssertEqual(record?.revision, 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
}
