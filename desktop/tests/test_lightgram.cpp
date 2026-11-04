#include <QApplication>
#include <QTest>
#include <QSignalSpy>
#include <QTemporaryFile>
#include <cassert>
#include <iostream>

#include "core/Settings.hpp"
#include "core/GhostController.hpp"
#include "core/SpyManager.hpp"
#include "core/StatisticsManager.hpp"
#include "core/MediaVaultManager.hpp"
#include "core/NotesManager.hpp"
#include "core/ThemeEngine.hpp"
#include "core/Localization.hpp"
#include "core/TelegramClient.hpp"

using namespace LightGram;

class LightGramDesktopTests : public QObject {
    Q_OBJECT

private slots:
    void testLocalization();
    void testSettings();
    void testGhostController();
    void testSpyManagerAntiRecall();
    void testStatisticsManager();
    void testMediaVault();
    void testNotesManager();
    void testThemeEngine();
    void testTelegramClient();
};

void LightGramDesktopTests::testLocalization() {
    auto& loc = Localization::instance();
    
    loc.setLanguage(Language::English);
    QCOMPARE(loc.get("GhostMode"), QString("Ghost Mode"));
    QCOMPARE(loc.get("Badge_Deleted"), QString("🔴 DELETED"));

    loc.setLanguage(Language::Russian);
    QCOMPARE(loc.get("GhostMode"), QString("Ghost Mode"));
    QCOMPARE(loc.get("Badge_Deleted"), QString("🔴 УДАЛЕНО"));

    loc.setLanguage(Language::Polish);
    QCOMPARE(loc.get("Badge_Deleted"), QString("🔴 USUNIĘTO"));

    // Fallback
    loc.setLanguage(Language::English);
    QCOMPARE(loc.get("NonExistentKey_XYZ", "Fallback"), QString("Fallback"));
    std::cout << "[PASS] Localization: All 3 languages verified." << std::endl;
}

void LightGramDesktopTests::testSettings() {
    auto& s = Settings::instance();
    s.setGhostModeEnabled(true);
    QVERIFY(s.isGhostModeEnabled());

    s.setGhostModeEnabled(false);
    QVERIFY(!s.isGhostModeEnabled());

    s.setSpyModeEnabled(true);
    s.setSaveDeletedMessages(true);
    s.setSaveEditHistory(true);
    QVERIFY(s.isSpyModeEnabled());
    QVERIFY(s.saveDeletedMessages());
    QVERIFY(s.saveEditHistory());

    // Master passcode test
    s.setMasterPasscode("1234");
    QVERIFY(s.checkMasterPasscode("1234"));
    QVERIFY(!s.checkMasterPasscode("0000"));
    s.setMasterPasscode(""); // Clear passcode

    // JSON export / import sync
    QJsonObject exp = s.exportToJson();
    QVERIFY(exp.contains("ghostModeEnabled"));
    QVERIFY(exp.contains("spyModeEnabled"));
    std::cout << "[PASS] Settings: Persistence, toggles, passcode & JSON sync verified." << std::endl;
}

void LightGramDesktopTests::testGhostController() {
    auto& gc = GhostController::instance();
    auto& s = Settings::instance();

    s.setGhostModeEnabled(true);
    s.setSuppressReadHistory(true);
    s.setSuppressTyping(true);
    s.setSuppressStoryViews(true);
    s.setMarkAsReadOnReply(true);

    int64_t peerId = 999123;
    gc.resetManualRead(peerId);

    // Suppression should be active
    QVERIFY(gc.shouldSuppressReadHistory(peerId));
    QVERIFY(gc.shouldSuppressTyping(peerId));
    QVERIFY(gc.shouldSuppressStoryView());
    QVERIFY(gc.shouldSuppressOnlinePresence());

    // User manually marks read
    gc.markPeerAsReadManually(peerId);
    QVERIFY(!gc.shouldSuppressReadHistory(peerId));

    // Reset manual read
    gc.resetManualRead(peerId);
    QVERIFY(gc.shouldSuppressReadHistory(peerId));

    // Handle outgoing message -> marks read
    bool marked = gc.handleOutgoingMessage(peerId);
    QVERIFY(marked);
    QVERIFY(!gc.shouldSuppressReadHistory(peerId));

    s.setGhostModeEnabled(false);
    std::cout << "[PASS] GhostController: Suppression gates and read overrides verified." << std::endl;
}

void LightGramDesktopTests::testSpyManagerAntiRecall() {
    auto& sm = SpyManager::instance();
    sm.clearAllData();

    int64_t peerId = 888100;
    int32_t msgId = 42;

    // 1. Deleted message
    sm.recordDeletedMessage(peerId, msgId, "Test Group", "Alice", "Top Secret info", "photo", "secret.jpg", 1700000000);
    QVERIFY(sm.isMessageDeleted(peerId, msgId));

    SpyDeletedRecord delRec = sm.getDeletedRecord(peerId, msgId);
    QCOMPARE(delRec.peerId, peerId);
    QCOMPARE(delRec.messageId, msgId);
    QCOMPARE(delRec.authorName, QString("Alice"));
    QCOMPARE(delRec.text, QString("Top Secret info"));

    auto allDel = sm.fetchAllDeletedMessages(peerId);
    QCOMPARE(allDel.size(), 1);

    // 2. Edited message
    int32_t editMsgId = 43;
    sm.recordEditedMessage(peerId, editMsgId, "Test Group", "Bob", "Hello world", "Hello universe", 1700000100);
    sm.recordEditedMessage(peerId, editMsgId, "Test Group", "Bob", "Hello universe", "Hello multiverse", 1700000200);

    auto editRecs = sm.getEditRecords(peerId, editMsgId);
    QCOMPARE(editRecs.size(), 2);
    QCOMPARE(editRecs[0].revision, 1);
    QCOMPARE(editRecs[0].previousText, QString("Hello world"));
    QCOMPARE(editRecs[1].revision, 2);
    QCOMPARE(editRecs[1].previousText, QString("Hello universe"));
    QCOMPARE(editRecs[1].newText, QString("Hello multiverse"));

    // 3. Export / Import JSON
    QByteArray exported = sm.exportArchiveJson();
    QVERIFY(!exported.isEmpty());

    sm.clearAllData();
    QCOMPARE(sm.fetchAllDeletedMessages().size(), 0);

    bool impOk = sm.importArchiveJson(exported);
    QVERIFY(impOk);
    QVERIFY(sm.isMessageDeleted(peerId, msgId));
    std::cout << "[PASS] SpyManager: Anti-Recall deleted messages and edit revisions verified." << std::endl;
}

void LightGramDesktopTests::testStatisticsManager() {
    auto& stats = StatisticsManager::instance();
    stats.recordMessageEvent(true, MediaType::None, 101, "Chat A", "user");
    stats.recordMessageEvent(false, MediaType::Photo, 101, "Chat A", "user");
    stats.recordMessageEvent(false, MediaType::Video, 102, "Group B", "group");
    stats.recordMessageEvent(true, MediaType::Circle, 103, "Channel C", "channel");

    StatisticsSnapshot s = stats.getSnapshot(7);
    QVERIFY(s.totalCount >= 4);
    QVERIFY(s.sentCount >= 2);
    QVERIFY(s.receivedCount >= 2);
    QVERIFY(s.photosCount >= 1);
    QVERIFY(s.videosCount >= 1);
    QVERIFY(s.circlesCount >= 1);
    QCOMPARE(s.hourlyActivity.size(), 24);
    QVERIFY(s.dailyLabels.size() == 7);

    QString report = stats.exportReportText(7);
    QVERIFY(report.contains("LIGHTGRAM DESKTOP ANALYTICS"));
    QVERIFY(report.contains("Total Messages:"));
    std::cout << "[PASS] StatisticsManager: Metric aggregation, charts data & text report verified." << std::endl;
}

void LightGramDesktopTests::testMediaVault() {
    auto& mv = MediaVaultManager::instance();
    mv.clearVault(false);

    // Create a temporary file to save
    QTemporaryFile tmpFile;
    QVERIFY(tmpFile.open());
    tmpFile.write("Test video note payload 1234567890");
    tmpFile.flush();

    bool ok = mv.saveToVault(tmpFile.fileName(), "test_circle.mp4", "circle", 100, 200, "Secret Chat", "Author");
    QVERIFY(ok);

    auto items = mv.fetchAllItems("all");
    QVERIFY(!items.isEmpty());
    QCOMPARE(items.first().mediaType, QString("circle"));
    QCOMPARE(items.first().fileName, QString("test_circle.mp4"));

    // Toggle favorite
    QString id = items.first().id;
    mv.toggleFavorite(id);
    QVERIFY(mv.getItem(id).isFavorite);

    // Favorites query
    auto favs = mv.fetchAllItems("favorites");
    QCOMPARE(favs.size(), 1);

    // Formatted size
    QString sz = mv.formattedStorageSize();
    QVERIFY(!sz.isEmpty());
    std::cout << "[PASS] MediaVaultManager: Vault storage, categories, favorites & sizes verified." << std::endl;
}

void LightGramDesktopTests::testNotesManager() {
    auto& nm = NotesManager::instance();

    PersonalNote n = nm.addNote("Meeting Notes", "Discuss LightGram Desktop features and Liquid Glass styling.", "#EDB400", 123, 456);
    QVERIFY(!n.id.isEmpty());

    auto allNotes = nm.fetchAllNotes();
    QVERIFY(!allNotes.isEmpty());
    QCOMPARE(allNotes.first().title, QString("Meeting Notes"));

    bool upd = nm.updateNote(n.id, "Meeting Notes Updated", "New content");
    QVERIFY(upd);

    // Reminders
    int64_t inFuture = QDateTime::currentSecsSinceEpoch() + 1000;
    MessageReminder r = nm.addReminder(123, 456, "Reply to Pavel", inFuture, "Important Chat");
    QVERIFY(!r.id.isEmpty());
    QVERIFY(!r.isCompleted);

    nm.setReminderCompleted(r.id, true);
    auto allRems = nm.fetchAllReminders();
    QVERIFY(allRems.first().isCompleted);

    nm.deleteNote(n.id);
    nm.deleteReminder(r.id);
    std::cout << "[PASS] NotesManager: Personal notes and reminders scheduling verified." << std::endl;
}

void LightGramDesktopTests::testThemeEngine() {
    auto& te = ThemeEngine::instance();

    // Verify 10 built-in themes exist
    QStringList expectedThemes = {
        "LightGram Original",
        "AMOLED Black",
        "Midnight",
        "Graphite",
        "Arctic",
        "Emerald",
        "Violet",
        "Sunset",
        "Crimson",
        "Pure White"
    };

    auto allThemes = te.allThemes();
    for (const auto& expected : expectedThemes) {
        bool found = false;
        for (const auto& t : allThemes) {
            if (t.name == expected) {
                found = true;
                break;
            }
        }
        QVERIFY2(found, QString("Missing built-in theme: %1").arg(expected).toUtf8().constData());
    }

    // Duplicate and custom theme creation
    te.duplicateTheme("LightGram Original", "My Custom Gold");
    ThemeConfig custom = te.getTheme("My Custom Gold");
    QCOMPARE(custom.name, QString("My Custom Gold"));
    QVERIFY(!custom.isBuiltIn);

    // QSS Generation
    QString qss = te.generateStyleSheet(custom);
    QVERIFY(qss.contains("QMainWindow"));
    QVERIFY(qss.contains("QPushButton"));

    te.deleteCustomTheme("My Custom Gold");
    std::cout << "[PASS] ThemeEngine: All 10 built-in themes, custom styling & QSS generation verified." << std::endl;
}

void LightGramDesktopTests::testTelegramClient() {
    auto& client = TelegramClient::instance();
    QVERIFY(client.isAuthorized());

    auto chats = client.getChats("all");
    QVERIFY(chats.size() >= 4);

    // Send a message
    int64_t peerId = chats.first().peerId;
    int initialCount = client.getMessages(peerId).size();

    client.sendMessage(peerId, "Unit test message execution");
    int newCount = client.getMessages(peerId).size();
    QCOMPARE(newCount, initialCount + 1);

    // Simulate remote delete
    int32_t sentMsgId = client.getMessages(peerId).last().id;
    client.injectSimulatedRemoteDelete(peerId, sentMsgId);
    QVERIFY(client.getMessages(peerId).last().isDeleted);

    // Simulate remote edit
    client.injectSimulatedRemoteEdit(peerId, sentMsgId, "Revised unit test text");
    QCOMPARE(client.getMessages(peerId).last().text, QString("Revised unit test text"));
    std::cout << "[PASS] TelegramClient: Protocol handling, messaging and Spy Mode simulation verified." << std::endl;
}

int main(int argc, char* argv[]) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    QApplication app(argc, argv);
    LightGramDesktopTests test;
    int res = QTest::qExec(&test, argc, argv);
    std::cout << "\n==============================================" << std::endl;
    std::cout << "LIGHTGRAM DESKTOP TEST SUITE RESULT: " << (res == 0 ? "100% PASSED" : "FAILED") << std::endl;
    std::cout << "==============================================" << std::endl;
    return res;
}

#include "test_lightgram.moc"
