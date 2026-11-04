#pragma once

#include "Types.hpp"
#include <QObject>
#include <QVector>
#include <QMap>
#include <QMutex>

namespace LightGram {

class SpyManager : public QObject {
    Q_OBJECT
public:
    static SpyManager& instance();

    void load();
    void persist();

    // Deleted messages
    bool isMessageDeleted(int64_t peerId, int32_t messageId) const;
    SpyDeletedRecord getDeletedRecord(int64_t peerId, int32_t messageId) const;
    void recordDeletedMessage(int64_t peerId, int32_t messageId, const QString& chatTitle,
                              const QString& authorName, const QString& text,
                              const QString& mediaType = QString(), const QString& mediaDesc = QString(),
                              int64_t originalTimestamp = 0);

    QVector<SpyDeletedRecord> fetchAllDeletedMessages(int64_t peerId = 0) const;

    // Edited messages
    QVector<SpyEditRecord> getEditRecords(int64_t peerId, int32_t messageId) const;
    void recordEditedMessage(int64_t peerId, int32_t messageId, const QString& chatTitle,
                             const QString& authorName, const QString& previousText,
                             const QString& newText, int64_t timestamp = 0);

    QVector<SpyEditRecord> fetchAllEditRecords(int64_t peerId = 0) const;

    // Maintenance & Management
    void deleteRecord(const QString& id, bool isDeletedMessage);
    void clearAllData();
    void enforceTTL();
    QString formattedArchiveSize() const;
    int64_t totalSizeBytes() const;

    // JSON Export / Import
    QByteArray exportArchiveJson() const;
    bool importArchiveJson(const QByteArray& data);

signals:
    void deletedMessageRecorded(const SpyDeletedRecord& record);
    void editRecordAdded(const SpyEditRecord& record);
    void archiveUpdated();

private:
    SpyManager();
    QString archiveFilePath() const;

    mutable QMutex m_mutex;
    QVector<SpyDeletedRecord> m_deletedCache;
    QVector<SpyEditRecord> m_editedCache;
    QMap<QString, SpyDeletedRecord> m_deletedMap; // "peerId_messageId" -> record
    QMap<QString, QVector<SpyEditRecord>> m_editedMap; // "peerId_messageId" -> list
};

} // namespace LightGram
