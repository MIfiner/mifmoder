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
            chatTitle: "Test Chat",
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
    
    func testSpyManagerDuplicatePrevention() {
        let spy = LightGramSpyManager.shared
        let expectation = self.expectation(description: "Duplicate prevention")
        
        let testPeerId: Int64 = 554433
        let testMsgId: Int32 = 777
        let testText = "Message that is deleted only once"
        let timestamp = Int32(Date().timeIntervalSince1970)
        
        spy.recordDeletedMessage(
            peerId: testPeerId,
            messageId: testMsgId,
            chatTitle: "Test Chat",
            authorName: "Tester",
            text: testText,
            mediaType: nil,
            originalTimestamp: timestamp
        )
        
        // Attempt duplicate recording
        spy.recordDeletedMessage(
            peerId: testPeerId,
            messageId: testMsgId,
            chatTitle: "Test Chat",
            authorName: "Tester",
            text: testText,
            mediaType: nil,
            originalTimestamp: timestamp
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            spy.fetchDeletedMessages(peerId: testPeerId) { records in
                let matching = records.filter { $0.peerId == testPeerId && $0.messageId == testMsgId }
                XCTAssertEqual(matching.count, 1, "Duplicate deleted message records must be prevented")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSpyManagerDeleteIndividualRecord() {
        let spy = LightGramSpyManager.shared
        let expectation = self.expectation(description: "Delete individual record")
        
        let testPeerId: Int64 = 443322
        let testMsgId: Int32 = 888
        let recordId = "\(testPeerId)_\(testMsgId)"
        
        spy.recordDeletedMessage(
            peerId: testPeerId,
            messageId: testMsgId,
            chatTitle: "Deletable Chat",
            authorName: "User",
            text: "To be removed",
            mediaType: nil,
            originalTimestamp: Int32(Date().timeIntervalSince1970)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            spy.deleteRecord(id: recordId, isDeletedMessage: true) {
                spy.fetchDeletedMessages(peerId: testPeerId) { records in
                    let found = records.first(where: { $0.id == recordId })
                    XCTAssertNil(found, "Record should be removed after deletion")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSpyManagerFastLookups() {
        let spy = LightGramSpyManager.shared
        let peerId: Int64 = 776655
        let messageId: Int32 = 999
        
        XCTAssertFalse(spy.isMessageDeleted(peerId: peerId, messageId: messageId))
        
        spy.markMessageAsDeleted(peerId: peerId, messageId: messageId, originalTimestamp: 1000, chatTitle: "Test Chat", authorName: "Alice", text: "Secret")
        
        XCTAssertTrue(spy.isMessageDeleted(peerId: peerId, messageId: messageId))
        let record = spy.getDeletedRecord(peerId: peerId, messageId: messageId)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.peerId, peerId)
        XCTAssertEqual(record?.messageId, messageId)
    }
    
    func testNotesManagerCRUD() {
        let notesManager = LightGramNotesManager.shared
        let expectation = self.expectation(description: "Notes CRUD")
        
        let testPeer: Int64 = 112233
        let testMsgId: Int32 = 333
        let noteText = "Important reminder for project launch"
        
        notesManager.addNote(peerId: testPeer, messageId: testMsgId, chatTitle: "Dev Group", authorName: "Lead", originalText: "Launch tomorrow", noteText: noteText) {
            notesManager.fetchAllNotes { notes in
                let found = notes.first(where: { $0.peerId == testPeer && $0.messageId == testMsgId })
                XCTAssertNotNil(found)
                XCTAssertEqual(found?.noteText, noteText)
                
                if let id = found?.id {
                    notesManager.deleteNote(id: id) {
                        notesManager.fetchAllNotes { notesAfter in
                            let after = notesAfter.first(where: { $0.id == id })
                            XCTAssertNil(after)
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testRemindersManagerCRUD() {
        let notesManager = LightGramNotesManager.shared
        let expectation = self.expectation(description: "Reminders CRUD")
        
        let testPeer: Int64 = 445566
        let testMsgId: Int32 = 444
        let msgText = "Check server logs at midnight"
        let remindDate = Date().addingTimeInterval(3600)
        
        notesManager.addReminder(peerId: testPeer, messageId: testMsgId, chatTitle: "Ops", messageText: msgText, remindAt: remindDate) {
            notesManager.fetchAllReminders { reminders in
                let found = reminders.first(where: { $0.peerId == testPeer && $0.messageId == testMsgId })
                XCTAssertNotNil(found)
                XCTAssertFalse(found?.isCompleted ?? true)
                
                if let id = found?.id {
                    notesManager.toggleReminderCompleted(id: id) {
                        notesManager.fetchAllReminders { remsAfter in
                            let toggled = remsAfter.first(where: { $0.id == id })
                            XCTAssertTrue(toggled?.isCompleted ?? false)
                            
                            notesManager.deleteReminder(id: id) {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testLogosAndLocalization() {
        // Test Logos count and attributes
        XCTAssertEqual(LightGramLogosController.availableLogos.count, 4)
        let ids = LightGramLogosController.availableLogos.map { $0.id }
        XCTAssertTrue(ids.contains("AmberIcon"))
        XCTAssertTrue(ids.contains("IceIcon"))
        XCTAssertTrue(ids.contains("VioletIcon"))
        XCTAssertTrue(ids.contains("EmeraldIcon"))
        
        // Test active logo theme setting
        LightGramSettings.shared.activeLogoTheme = "EmeraldIcon"
        XCTAssertEqual(LightGramSettings.shared.activeLogoTheme, "EmeraldIcon")
        LightGramSettings.shared.activeLogoTheme = "AmberIcon"
        XCTAssertEqual(LightGramSettings.shared.activeLogoTheme, "AmberIcon")
        
        // Test Localization
        XCTAssertFalse(LightGramStrings.tr("GhostMode").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("SpyMode").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("Logos_Title").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("Badge_Deleted").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("Badge_Edited").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("Statistics_Title").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("MediaVault_Title").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("CircleStudio_Title").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("MediaVault_SaveToVault").isEmpty)
        XCTAssertFalse(LightGramStrings.tr("MediaVault_ForwardNormal").isEmpty)
    }
    
    func testMediaVaultOperations() {
        let vault = LightGramMediaVaultManager.shared
        
        // Create dummy file in temp
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let dummyURL = tempDir.appendingPathComponent("test_circle.mp4")
        try? "dummy media bytes".data(using: .utf8)?.write(to: dummyURL)
        
        let expectation = self.expectation(description: "saveDirectFile")
        
        vault.saveDirectFile(
            sourceURL: dummyURL,
            fileName: "test_circle.mp4",
            mediaType: "circle",
            chatTitle: "Test Chat",
            authorName: "Alice",
            isOneTime: true,
            duration: 15.0,
            dimensions: "720x720"
        ) { success, _ in
            XCTAssertTrue(success)
            
            let allItems = vault.getItems()
            let found = allItems.first(where: { $0.fileName == "test_circle.mp4" })
            XCTAssertNotNil(found)
            XCTAssertEqual(found?.mediaType, "circle")
            XCTAssertTrue(found?.isOneTime ?? false)
            XCTAssertEqual(found?.duration, 15.0)
            
            if let itemId = found?.id {
                // Test toggle favorite
                let isFav = vault.toggleFavorite(id: itemId)
                XCTAssertTrue(isFav)
                
                let favs = vault.getItems(favoritesOnly: true)
                XCTAssertTrue(favs.contains(where: { $0.id == itemId }))
                
                // Test filter by type
                let circles = vault.getItems(typeFilter: "circle")
                XCTAssertTrue(circles.contains(where: { $0.id == itemId }))
                
                let photos = vault.getItems(typeFilter: "photo")
                XCTAssertFalse(photos.contains(where: { $0.id == itemId }))
                
                // Test storage analytics
                XCTAssertTrue(vault.totalStorageBytes() > 0)
                XCTAssertFalse(vault.formattedStorageSize().isEmpty)
                
                // Test delete
                vault.deleteItem(id: itemId) { deleted in
                    XCTAssertTrue(deleted)
                    let remaining = vault.getItems()
                    XCTAssertFalse(remaining.contains(where: { $0.id == itemId }))
                    expectation.fulfill()
                }
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testStatisticsSnapshotStructure() {
        let snapshot = LightGramStatisticsSnapshot(
            periodIndex: 0,
            startDateTimestamp: 1000,
            endDateTimestamp: 2000,
            sentMessagesCount: 42,
            receivedMessagesCount: 58,
            totalMessagesCount: 100,
            activeChatsCount: 5,
            photosCount: 12,
            videosCount: 4,
            circlesCount: 8,
            voiceCount: 15,
            filesCount: 3,
            hourlyActivity: [Int](repeating: 2, count: 24),
            dailyActivityLabels: ["Mon", "Tue", "Wed"],
            dailyActivityCounts: [30, 40, 30],
            topChats: [
                TopChatStat(peerId: 101, title: "Alice", messageCount: 50, percentage: 50.0, peerType: "user"),
                TopChatStat(peerId: 102, title: "Dev Group", messageCount: 50, percentage: 50.0, peerType: "group")
            ],
            peakDayLabel: "Tue",
            peakHourLabel: "14:00 - 15:00",
            averageMessagesPerDay: 14.3,
            deletedMessagesCount: 6,
            editedRevisionsCount: 9,
            vaultItemsCount: 3,
            vaultStorageFormatted: "12.4 MB",
            isRealData: true
        )
        
        XCTAssertEqual(snapshot.totalMessagesCount, 100)
        XCTAssertEqual(snapshot.sentMessagesCount, 42)
        XCTAssertEqual(snapshot.receivedMessagesCount, 58)
        XCTAssertEqual(snapshot.activeChatsCount, 5)
        XCTAssertEqual(snapshot.topChats.count, 2)
        XCTAssertEqual(snapshot.topChats.first?.percentage, 50.0)
        XCTAssertTrue(snapshot.isRealData)
        XCTAssertEqual(snapshot.peakDayLabel, "Tue")
        XCTAssertEqual(snapshot.peakHourLabel, "14:00 - 15:00")
    }
}
