#include "TelegramClient.hpp"
#include "GhostController.hpp"
#include "SpyManager.hpp"
#include "StatisticsManager.hpp"
#include "Settings.hpp"
#include <QDateTime>
#include <QFileInfo>
#include <QHostInfo>

namespace LightGram {

TelegramClient& TelegramClient::instance() {
    static TelegramClient inst;
    return inst;
}

TelegramClient::TelegramClient() {
    // Official Telegram DC endpoints (MTProto / TCP 443)
    m_dataCenters = {
        { 1, "DC1 (Miami, USA)", "149.154.175.50", 443 },
        { 2, "DC2 (Amsterdam, Europe)", "149.154.167.51", 443 },
        { 3, "DC3 (Miami, USA)", "149.154.175.100", 443 },
        { 4, "DC4 (Amsterdam, Europe)", "149.154.167.91", 443 },
        { 5, "DC5 (Singapore, Asia)", "91.108.56.130", 443 }
    };

    populateInitialChats();
}

void TelegramClient::populateInitialChats() {
    int64_t now = QDateTime::currentSecsSinceEpoch();

    // 1. LightGram Official News
    {
        ChatSummary c;
        c.peerId = 1001;
        c.title = "LightGram Official";
        c.type = PeerType::Channel;
        c.unreadCount = 2;
        c.isPinned = true;
        c.lastMessage = "LightGram Desktop v1.0 is here with Liquid Glass & iOS 27 design!";
        c.lastMessageTime = now - 120;
        m_chats[c.peerId] = c;

        QVector<MessageItem> msgs;
        MessageItem m1;
        m1.id = 1;
        m1.peerId = c.peerId;
        m1.senderId = 999;
        m1.senderName = "LightGram Channel";
        m1.text = "Welcome to LightGram Desktop — the premier Telegram client for Windows, macOS, and Linux!";
        m1.timestamp = now - 3600;
        msgs.append(m1);

        MessageItem m2;
        m2.id = 2;
        m2.peerId = c.peerId;
        m2.senderId = 999;
        m2.senderName = "LightGram Channel";
        m2.text = "Liquid Glass UI, Ghost Mode, and Spy Mode Anti-Recall are fully enabled.";
        m2.timestamp = now - 120;
        msgs.append(m2);

        m_messages[c.peerId] = msgs;
    }

    // 2. Secret Lab (Demonstrating Inline Spy Mode: Deleted & Edited Messages)
    {
        ChatSummary c;
        c.peerId = 1002;
        c.title = "Spy Mode Demo Lab";
        c.type = PeerType::Group;
        c.unreadCount = 0;
        c.isPinned = true;
        c.lastMessage = "Try editing or deleting a message to see the inline badges!";
        c.lastMessageTime = now - 300;
        m_chats[c.peerId] = c;

        QVector<MessageItem> msgs;
        MessageItem m1;
        m1.id = 10;
        m1.peerId = c.peerId;
        m1.senderId = 200;
        m1.senderName = "Alex Developer";
        m1.text = "Hey! This is a test message that was sent normally.";
        m1.timestamp = now - 900;
        msgs.append(m1);

        // Pre-recorded deleted message
        MessageItem m2;
        m2.id = 11;
        m2.peerId = c.peerId;
        m2.senderId = 200;
        m2.senderName = "Alex Developer";
        m2.text = "Confidential API keys and server passwords (accidentally sent!)";
        m2.timestamp = now - 800;
        m2.isDeleted = true;
        m2.deletionTimestamp = now - 750;
        msgs.append(m2);

        // Record in SpyManager
        SpyManager::instance().recordDeletedMessage(c.peerId, m2.id, c.title, m2.senderName, m2.text, "", "", m2.timestamp);

        // Pre-recorded edited message
        MessageItem m3;
        m3.id = 12;
        m3.peerId = c.peerId;
        m3.senderId = 201;
        m3.senderName = "Elena Project Lead";
        m3.text = "Meeting rescheduled to 4:00 PM tomorrow in room 302.";
        m3.timestamp = now - 500;
        
        SpyEditRecord rev;
        rev.id = QString("%1_12_rev1").arg(c.peerId);
        rev.peerId = c.peerId;
        rev.messageId = 12;
        rev.chatTitle = c.title;
        rev.authorName = m3.senderName;
        rev.previousText = "Meeting is at 2:00 PM today in the lobby.";
        rev.newText = m3.text;
        rev.timestamp = now - 450;
        rev.revision = 1;
        m3.editRevisions.append(rev);
        msgs.append(m3);

        SpyManager::instance().recordEditedMessage(c.peerId, 12, c.title, m3.senderName, rev.previousText, rev.newText, rev.timestamp);

        MessageItem m4;
        m4.id = 13;
        m4.peerId = c.peerId;
        m4.senderId = 1; // You
        m4.isOutgoing = true;
        m4.senderName = "You";
        m4.text = "Got it! Notice how deleted messages have a red border and edited ones have an amber border.";
        m4.timestamp = now - 300;
        msgs.append(m4);

        m_messages[c.peerId] = msgs;
    }

    // 3. Pavel Durov
    {
        ChatSummary c;
        c.peerId = 1003;
        c.title = "Pavel Durov";
        c.type = PeerType::User;
        c.unreadCount = 1;
        c.isOnline = true;
        c.lastMessage = "Great job on bringing LightGram to Desktop.";
        c.lastMessageTime = now - 600;
        m_chats[c.peerId] = c;

        QVector<MessageItem> msgs;
        MessageItem m1;
        m1.id = 21;
        m1.peerId = c.peerId;
        m1.senderId = c.peerId;
        m1.senderName = "Pavel Durov";
        m1.text = "Great job on bringing LightGram to Desktop. The Liquid Glass style feels native and smooth.";
        m1.timestamp = now - 600;
        msgs.append(m1);
        m_messages[c.peerId] = msgs;
    }

    // 4. Saved Messages
    {
        ChatSummary c;
        c.peerId = 1004;
        c.title = "Saved Messages";
        c.type = PeerType::User;
        c.unreadCount = 0;
        c.lastMessage = "Notes, links, and documents";
        c.lastMessageTime = now - 7200;
        m_chats[c.peerId] = c;

        QVector<MessageItem> msgs;
        MessageItem m1;
        m1.id = 31;
        m1.peerId = c.peerId;
        m1.senderId = 1;
        m1.isOutgoing = true;
        m1.senderName = "You";
        m1.text = "Telegram MTProto API credentials:\napi_id: 8\napi_hash: 7245de8e747a0d6fbe11f7cc14fcc0bb";
        m1.timestamp = now - 7200;
        msgs.append(m1);
        m_messages[c.peerId] = msgs;
    }

    // 5. BotFather
    {
        ChatSummary c;
        c.peerId = 1005;
        c.title = "BotFather";
        c.type = PeerType::Bot;
        c.unreadCount = 0;
        c.lastMessage = "I can help you create and manage Telegram bots.";
        c.lastMessageTime = now - 86400;
        m_chats[c.peerId] = c;

        QVector<MessageItem> msgs;
        MessageItem m1;
        m1.id = 41;
        m1.peerId = c.peerId;
        m1.senderId = c.peerId;
        m1.senderName = "BotFather";
        m1.text = "I can help you create and manage Telegram bots. Use /newbot to begin.";
        m1.timestamp = now - 86400;
        msgs.append(m1);
        m_messages[c.peerId] = msgs;
    }
}

void TelegramClient::startConnection() {
    m_state = ConnectionState::Ready;
    emit stateChanged(m_state);
}

void TelegramClient::sendPhoneNumber(const QString& phoneNumber) {
    m_currentPhone = phoneNumber;
    m_state = ConnectionState::WaitingForCode;
    emit stateChanged(m_state);
}

void TelegramClient::sendAuthCode(const QString& code) {
    if (code == "12345" || code.length() >= 5) {
        m_state = ConnectionState::Ready;
        emit stateChanged(m_state);
    } else {
        emit authError("Invalid authorization code. Please try again.");
    }
}

void TelegramClient::sendPassword(const QString& password) {
    Q_UNUSED(password);
    m_state = ConnectionState::Ready;
    emit stateChanged(m_state);
}

void TelegramClient::requestQrCode() {
    emit qrCodeGenerated("https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=tg://login?token=lightgram-desktop");
}

void TelegramClient::logOut() {
    m_state = ConnectionState::WaitingForPhoneNumber;
    emit stateChanged(m_state);
}

void TelegramClient::switchAccount(int index) {
    m_activeAccountIndex = index;
    emit chatsUpdated();
}

QVector<QString> TelegramClient::availableAccounts() const {
    return { "Primary Account (+1 800 555-0199)", "Work Account (+44 20 7946-0912)", "Secondary (+48 22 123-4567)" };
}

QVector<ChatSummary> TelegramClient::getChats(const QString& folderId) const {
    QVector<ChatSummary> list;
    for (const auto& c : m_chats) {
        if (folderId == "unread" && c.unreadCount == 0) continue;
        if (folderId == "personal" && c.type != PeerType::User) continue;
        if (folderId == "groups" && c.type != PeerType::Group && c.type != PeerType::Supergroup) continue;
        if (folderId == "channels" && c.type != PeerType::Channel) continue;
        if (folderId == "bots" && c.type != PeerType::Bot) continue;
        list.append(c);
    }
    return list;
}

ChatSummary TelegramClient::getChat(int64_t peerId) const {
    return m_chats.value(peerId);
}

QVector<MessageItem> TelegramClient::getMessages(int64_t peerId, int limit) const {
    Q_UNUSED(limit);
    return m_messages.value(peerId);
}

void TelegramClient::sendMessage(int64_t peerId, const QString& text, int32_t replyToId) {
    if (text.trimmed().isEmpty()) return;

    MessageItem msg;
    msg.id = (int32_t)(QDateTime::currentMSecsSinceEpoch() % 100000000);
    msg.peerId = peerId;
    msg.senderId = 1; // User
    msg.isOutgoing = true;
    msg.senderName = "You";
    msg.text = text;
    msg.timestamp = QDateTime::currentSecsSinceEpoch();
    msg.replyToMessageId = replyToId;

    m_messages[peerId].append(msg);

    if (m_chats.contains(peerId)) {
        m_chats[peerId].lastMessage = text;
        m_chats[peerId].lastMessageTime = msg.timestamp;
    }

    // Ghost Mode: Auto-mark as read on reply
    GhostController::instance().handleOutgoingMessage(peerId);

    // Record stats
    StatisticsManager::instance().recordMessageEvent(true, MediaType::None, peerId,
                                                     m_chats.value(peerId).title, "user");

    emit messageReceived(msg);
    emit chatsUpdated();
}

void TelegramClient::sendMediaFile(int64_t peerId, const QString& filePath, const QString& caption) {
    QFileInfo fi(filePath);
    if (!fi.exists()) return;

    MediaType mt = MediaType::Document;
    QString suf = fi.suffix().toLower();
    if (suf == "jpg" || suf == "jpeg" || suf == "png" || suf == "webp") mt = MediaType::Photo;
    else if (suf == "mp4" || suf == "mov" || suf == "mkv") mt = MediaType::Video;
    else if (suf == "mp3" || suf == "m4a" || suf == "ogg") mt = MediaType::Voice;

    MessageItem msg;
    msg.id = (int32_t)(QDateTime::currentMSecsSinceEpoch() % 100000000);
    msg.peerId = peerId;
    msg.senderId = 1;
    msg.isOutgoing = true;
    msg.senderName = "You";
    msg.text = caption;
    msg.timestamp = QDateTime::currentSecsSinceEpoch();
    msg.mediaType = mt;
    msg.mediaLocalPath = filePath;
    msg.mediaCaption = caption;
    msg.mediaSizeBytes = fi.size();

    m_messages[peerId].append(msg);

    if (m_chats.contains(peerId)) {
        m_chats[peerId].lastMessage = caption.isEmpty() ? QString("[%1: %2]").arg(suf.toUpper()).arg(fi.fileName()) : caption;
        m_chats[peerId].lastMessageTime = msg.timestamp;
    }

    GhostController::instance().handleOutgoingMessage(peerId);
    StatisticsManager::instance().recordMessageEvent(true, mt, peerId, m_chats.value(peerId).title, "user");

    emit messageReceived(msg);
    emit chatsUpdated();
}

void TelegramClient::markAsRead(int64_t peerId) {
    // If Ghost Mode suppression is active, do not mark as read unless manually triggered
    if (GhostController::instance().shouldSuppressReadHistory(peerId)) {
        return;
    }

    if (m_chats.contains(peerId)) {
        m_chats[peerId].unreadCount = 0;
        emit chatsUpdated();
    }
}

void TelegramClient::deleteMessage(int64_t peerId, int32_t messageId, bool revokeForAll) {
    Q_UNUSED(revokeForAll);
    if (!m_messages.contains(peerId)) return;

    for (int i = 0; i < m_messages[peerId].size(); ++i) {
        if (m_messages[peerId][i].id == messageId) {
            m_messages[peerId].removeAt(i);
            break;
        }
    }
    emit messageDeleted(peerId, messageId);
}

void TelegramClient::injectSimulatedIncomingMessage(int64_t peerId, const QString& senderName, const QString& text) {
    MessageItem msg;
    msg.id = (int32_t)(QDateTime::currentMSecsSinceEpoch() % 100000000);
    msg.peerId = peerId;
    msg.senderId = 555;
    msg.isOutgoing = false;
    msg.senderName = senderName;
    msg.text = text;
    msg.timestamp = QDateTime::currentSecsSinceEpoch();

    m_messages[peerId].append(msg);

    if (m_chats.contains(peerId)) {
        m_chats[peerId].lastMessage = text;
        m_chats[peerId].lastMessageTime = msg.timestamp;
        m_chats[peerId].unreadCount++;
    }

    StatisticsManager::instance().recordMessageEvent(false, MediaType::None, peerId,
                                                     m_chats.value(peerId).title, "user");

    emit messageReceived(msg);
    emit chatsUpdated();
}

void TelegramClient::injectSimulatedRemoteDelete(int64_t peerId, int32_t messageId) {
    if (!m_messages.contains(peerId)) return;

    for (int i = 0; i < m_messages[peerId].size(); ++i) {
        if (m_messages[peerId][i].id == messageId) {
            auto& msg = m_messages[peerId][i];
            msg.isDeleted = true;
            msg.deletionTimestamp = QDateTime::currentSecsSinceEpoch();

            // Record in SpyManager
            SpyManager::instance().recordDeletedMessage(peerId, messageId, m_chats.value(peerId).title,
                                                        msg.senderName, msg.text, "", "", msg.timestamp);
            emit messageUpdated(msg);
            break;
        }
    }
}

void TelegramClient::injectSimulatedRemoteEdit(int64_t peerId, int32_t messageId, const QString& newText) {
    if (!m_messages.contains(peerId)) return;

    for (int i = 0; i < m_messages[peerId].size(); ++i) {
        if (m_messages[peerId][i].id == messageId) {
            auto& msg = m_messages[peerId][i];
            QString oldText = msg.text;
            msg.text = newText;

            SpyEditRecord rev;
            rev.id = QString("%1_%2_rev%3").arg(peerId).arg(messageId).arg(msg.editRevisions.size() + 1);
            rev.peerId = peerId;
            rev.messageId = messageId;
            rev.chatTitle = m_chats.value(peerId).title;
            rev.authorName = msg.senderName;
            rev.previousText = oldText;
            rev.newText = newText;
            rev.timestamp = QDateTime::currentSecsSinceEpoch();
            rev.revision = msg.editRevisions.size() + 1;

            msg.editRevisions.append(rev);
            SpyManager::instance().recordEditedMessage(peerId, messageId, m_chats.value(peerId).title,
                                                       msg.senderName, oldText, newText, rev.timestamp);
            emit messageUpdated(msg);
            break;
        }
    }
}

void TelegramClient::pingDataCenters() {
    for (const auto& dc : m_dataCenters) {
        QTcpSocket* socket = new QTcpSocket(this);
        QElapsedTimer* timer = new QElapsedTimer();
        timer->start();

        int dcId = dc.id;
        QString dcName = dc.name;
        QString dcHost = dc.host;

        connect(socket, &QTcpSocket::connected, [this, socket, timer, dcId, dcName, dcHost]() {
            int rtt = (int)timer->elapsed();
            socket->disconnectFromHost();
            socket->deleteLater();
            delete timer;
            emit dcPingResult(dcId, dcName, dcHost, rtt, true);
        });

        connect(socket, &QTcpSocket::errorOccurred, [this, socket, timer, dcId, dcName, dcHost](QAbstractSocket::SocketError) {
            socket->deleteLater();
            delete timer;
            emit dcPingResult(dcId, dcName, dcHost, 999, false);
        });

        socket->connectToHost(dc.host, dc.port);
    }
}

void TelegramClient::handleSocketConnected() {}
void TelegramClient::handleSocketError() {}

} // namespace LightGram
