#pragma once

#include <QString>
#include <QDateTime>
#include <QColor>
#include <QVector>
#include <QJsonObject>
#include <QJsonArray>
#include <cstdint>

namespace LightGram {

// Type of peer (dialog target)
enum class PeerType {
    User,
    Group,
    Supergroup,
    Channel,
    Bot
};

// Types of media attachment
enum class MediaType {
    None,
    Photo,
    Video,
    Circle, // Video note 1:1
    Voice,
    Document,
    Audio,
    Sticker,
    Animation // GIF
};

// Record of deleted message captured by Spy Mode Anti-Recall
struct SpyDeletedRecord {
    QString id;
    int64_t peerId = 0;
    int32_t messageId = 0;
    QString chatTitle;
    QString authorName;
    QString text;
    QString mediaType;
    QString mediaDescription;
    int64_t originalTimestamp = 0;
    int64_t deletionTimestamp = 0;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["peerId"] = QString::number(peerId);
        obj["messageId"] = messageId;
        obj["chatTitle"] = chatTitle;
        obj["authorName"] = authorName;
        obj["text"] = text;
        obj["mediaType"] = mediaType;
        obj["mediaDescription"] = mediaDescription;
        obj["originalTimestamp"] = (qint64)originalTimestamp;
        obj["deletionTimestamp"] = (qint64)deletionTimestamp;
        return obj;
    }

    static SpyDeletedRecord fromJson(const QJsonObject& obj) {
        SpyDeletedRecord r;
        r.id = obj["id"].toString();
        r.peerId = obj["peerId"].toString().toLongLong();
        r.messageId = obj["messageId"].toInt();
        r.chatTitle = obj["chatTitle"].toString();
        r.authorName = obj["authorName"].toString();
        r.text = obj["text"].toString();
        r.mediaType = obj["mediaType"].toString();
        r.mediaDescription = obj["mediaDescription"].toString();
        r.originalTimestamp = obj["originalTimestamp"].toVariant().toLongLong();
        r.deletionTimestamp = obj["deletionTimestamp"].toVariant().toLongLong();
        return r;
    }
};

// Record of message edition revision captured by Spy Mode
struct SpyEditRecord {
    QString id;
    int64_t peerId = 0;
    int32_t messageId = 0;
    QString chatTitle;
    QString authorName;
    QString previousText;
    QString newText;
    int64_t timestamp = 0;
    int revision = 1;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["peerId"] = QString::number(peerId);
        obj["messageId"] = messageId;
        obj["chatTitle"] = chatTitle;
        obj["authorName"] = authorName;
        obj["previousText"] = previousText;
        obj["newText"] = newText;
        obj["timestamp"] = (qint64)timestamp;
        obj["revision"] = revision;
        return obj;
    }

    static SpyEditRecord fromJson(const QJsonObject& obj) {
        SpyEditRecord r;
        r.id = obj["id"].toString();
        r.peerId = obj["peerId"].toString().toLongLong();
        r.messageId = obj["messageId"].toInt();
        r.chatTitle = obj["chatTitle"].toString();
        r.authorName = obj["authorName"].toString();
        r.previousText = obj["previousText"].toString();
        r.newText = obj["newText"].toString();
        r.timestamp = obj["timestamp"].toVariant().toLongLong();
        r.revision = obj["revision"].toInt(1);
        return r;
    }
};

// Timeline message representation
struct MessageItem {
    int32_t id = 0;
    int64_t peerId = 0;
    int64_t senderId = 0;
    QString senderName;
    QString text;
    int64_t timestamp = 0;
    bool isOutgoing = false;
    bool isRead = false;
    
    // Spy Mode flags & history
    bool isDeleted = false;
    int64_t deletionTimestamp = 0;
    QVector<SpyEditRecord> editRevisions;
    
    // Media attributes
    MediaType mediaType = MediaType::None;
    QString mediaLocalPath;
    QString mediaCaption;
    int64_t mediaSizeBytes = 0;
    int mediaDurationSeconds = 0;
    int mediaWidth = 0;
    int mediaHeight = 0;
    
    // Forward & Reply
    int32_t replyToMessageId = 0;
    QString forwardFromName;
};

// Secure Media Vault record
struct MediaVaultItem {
    QString id;
    int32_t messageId = 0;
    int64_t peerId = 0;
    QString mediaType; // photo, video, circle, voice, file
    QString fileName;
    QString relativePath;
    int64_t fileSize = 0;
    int64_t savedTimestamp = 0;
    bool isFavorite = false;
    QString senderName;
    QString chatTitle;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["messageId"] = messageId;
        obj["peerId"] = QString::number(peerId);
        obj["mediaType"] = mediaType;
        obj["fileName"] = fileName;
        obj["relativePath"] = relativePath;
        obj["fileSize"] = (qint64)fileSize;
        obj["savedTimestamp"] = (qint64)savedTimestamp;
        obj["isFavorite"] = isFavorite;
        obj["senderName"] = senderName;
        obj["chatTitle"] = chatTitle;
        return obj;
    }

    static MediaVaultItem fromJson(const QJsonObject& obj) {
        MediaVaultItem it;
        it.id = obj["id"].toString();
        it.messageId = obj["messageId"].toInt();
        it.peerId = obj["peerId"].toString().toLongLong();
        it.mediaType = obj["mediaType"].toString();
        it.fileName = obj["fileName"].toString();
        it.relativePath = obj["relativePath"].toString();
        it.fileSize = obj["fileSize"].toVariant().toLongLong();
        it.savedTimestamp = obj["savedTimestamp"].toVariant().toLongLong();
        it.isFavorite = obj["isFavorite"].toBool();
        it.senderName = obj["senderName"].toString();
        it.chatTitle = obj["chatTitle"].toString();
        return it;
    }
};

// Personal Notes & Reminders
struct PersonalNote {
    QString id;
    QString title;
    QString content;
    int64_t createdTimestamp = 0;
    int64_t updatedTimestamp = 0;
    QString colorTag = "#EDB400";
    int64_t linkedPeerId = 0;
    int32_t linkedMessageId = 0;
};

struct MessageReminder {
    QString id;
    int32_t messageId = 0;
    int64_t peerId = 0;
    QString note;
    int64_t triggerTimestamp = 0;
    bool isCompleted = false;
    QString chatTitle;
};

// Smart Folders
struct SmartFolder {
    QString id;
    QString name;
    QString icon;
    bool isEnabled = true;
    int badgeCount = 0;
};

// Chat Summary for Sidebar
struct ChatSummary {
    int64_t peerId = 0;
    QString title;
    QString lastMessage;
    int64_t lastMessageTime = 0;
    int unreadCount = 0;
    bool isPinned = false;
    bool isMuted = false;
    bool isOnline = false;
    PeerType type = PeerType::User;
    QString draftText;
};

// Top Chat Statistic
struct TopChatStat {
    int64_t peerId = 0;
    QString title;
    int messageCount = 0;
    double percentage = 0.0;
    QString peerType; // user, group, channel
};

// Statistics Snapshot
struct StatisticsSnapshot {
    int periodDays = 7; // 7, 30, 0 (all)
    int64_t generatedTimestamp = 0;
    int sentCount = 0;
    int receivedCount = 0;
    int totalCount = 0;
    int activeChatsCount = 0;

    int photosCount = 0;
    int videosCount = 0;
    int circlesCount = 0;
    int voiceCount = 0;
    int filesCount = 0;

    QVector<int> hourlyActivity; // 24 values
    QVector<QString> dailyLabels;
    QVector<int> dailyCounts;

    QVector<TopChatStat> topChats;

    QString peakHour;
    QString peakDay;
    double avgPerDay = 0.0;
    int savedDeletedCount = 0;
    int savedEditsCount = 0;
    int vaultItemsCount = 0;
    QString vaultStorageFormatted;
};

} // namespace LightGram
