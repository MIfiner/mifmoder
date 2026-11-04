#include "SpyManager.hpp"
#include "Settings.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

namespace LightGram {

SpyManager& SpyManager::instance() {
    static SpyManager inst;
    return inst;
}

SpyManager::SpyManager() {
    load();
    enforceTTL();
}

QString SpyManager::archiveFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir dir(configDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    return dir.filePath("lightgram_spy_archive.json");
}

void SpyManager::load() {
    QMutexLocker locker(&m_mutex);
    QFile file(archiveFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        return;
    }

    QJsonObject root = doc.object();
    m_deletedCache.clear();
    m_deletedMap.clear();
    m_editedCache.clear();
    m_editedMap.clear();

    QJsonArray delArr = root.value("deleted").toArray();
    for (const auto& val : delArr) {
        SpyDeletedRecord r = SpyDeletedRecord::fromJson(val.toObject());
        m_deletedCache.append(r);
        QString key = QString("%1_%2").arg(r.peerId).arg(r.messageId);
        m_deletedMap[key] = r;
    }

    QJsonArray editArr = root.value("edited").toArray();
    for (const auto& val : editArr) {
        SpyEditRecord r = SpyEditRecord::fromJson(val.toObject());
        m_editedCache.append(r);
        QString key = QString("%1_%2").arg(r.peerId).arg(r.messageId);
        m_editedMap[key].append(r);
    }
}

void SpyManager::persist() {
    QFile file(archiveFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        return;
    }

    QJsonObject root;
    QJsonArray delArr;
    for (const auto& r : m_deletedCache) {
        delArr.append(r.toJson());
    }
    root["deleted"] = delArr;

    QJsonArray editArr;
    for (const auto& r : m_editedCache) {
        editArr.append(r.toJson());
    }
    root["edited"] = editArr;

    QJsonDocument doc(root);
    file.write(doc.toJson(QJsonDocument::Compact));
}

bool SpyManager::isMessageDeleted(int64_t peerId, int32_t messageId) const {
    QMutexLocker locker(&m_mutex);
    QString key = QString("%1_%2").arg(peerId).arg(messageId);
    return m_deletedMap.contains(key);
}

SpyDeletedRecord SpyManager::getDeletedRecord(int64_t peerId, int32_t messageId) const {
    QMutexLocker locker(&m_mutex);
    QString key = QString("%1_%2").arg(peerId).arg(messageId);
    return m_deletedMap.value(key);
}

void SpyManager::recordDeletedMessage(int64_t peerId, int32_t messageId, const QString& chatTitle,
                                      const QString& authorName, const QString& text,
                                      const QString& mediaType, const QString& mediaDesc,
                                      int64_t originalTimestamp) {
    if (!Settings::instance().isSpyModeEnabled() || !Settings::instance().saveDeletedMessages()) {
        return;
    }

    SpyDeletedRecord record;
    record.id = QString("%1_%2").arg(peerId).arg(messageId);
    record.peerId = peerId;
    record.messageId = messageId;
    record.chatTitle = chatTitle.isEmpty() ? "Chat" : chatTitle;
    record.authorName = authorName.isEmpty() ? "Unknown" : authorName;
    record.text = text;
    record.mediaType = mediaType;
    record.mediaDescription = mediaDesc;
    record.originalTimestamp = originalTimestamp > 0 ? originalTimestamp : QDateTime::currentSecsSinceEpoch();
    record.deletionTimestamp = QDateTime::currentSecsSinceEpoch();

    {
        QMutexLocker locker(&m_mutex);
        m_deletedCache.prepend(record);
        m_deletedMap[record.id] = record;
        persist();
    }

    emit deletedMessageRecorded(record);
    emit archiveUpdated();
}

QVector<SpyDeletedRecord> SpyManager::fetchAllDeletedMessages(int64_t peerId) const {
    QMutexLocker locker(&m_mutex);
    if (peerId == 0) {
        return m_deletedCache;
    }
    QVector<SpyDeletedRecord> filtered;
    for (const auto& r : m_deletedCache) {
        if (r.peerId == peerId) {
            filtered.append(r);
        }
    }
    return filtered;
}

QVector<SpyEditRecord> SpyManager::getEditRecords(int64_t peerId, int32_t messageId) const {
    QMutexLocker locker(&m_mutex);
    QString key = QString("%1_%2").arg(peerId).arg(messageId);
    return m_editedMap.value(key);
}

void SpyManager::recordEditedMessage(int64_t peerId, int32_t messageId, const QString& chatTitle,
                                     const QString& authorName, const QString& previousText,
                                     const QString& newText, int64_t timestamp) {
    if (!Settings::instance().isSpyModeEnabled() || !Settings::instance().saveEditHistory()) {
        return;
    }
    if (previousText == newText || previousText.isEmpty()) {
        return;
    }

    QString key = QString("%1_%2").arg(peerId).arg(messageId);
    int revision = 1;
    {
        QMutexLocker locker(&m_mutex);
        if (m_editedMap.contains(key)) {
            revision = m_editedMap[key].size() + 1;
        }
    }

    SpyEditRecord record;
    record.id = QString("%1_%2_rev%3").arg(peerId).arg(messageId).arg(revision);
    record.peerId = peerId;
    record.messageId = messageId;
    record.chatTitle = chatTitle.isEmpty() ? "Chat" : chatTitle;
    record.authorName = authorName.isEmpty() ? "Unknown" : authorName;
    record.previousText = previousText;
    record.newText = newText;
    record.timestamp = timestamp > 0 ? timestamp : QDateTime::currentSecsSinceEpoch();
    record.revision = revision;

    {
        QMutexLocker locker(&m_mutex);
        m_editedCache.prepend(record);
        m_editedMap[key].append(record);
        persist();
    }

    emit editRecordAdded(record);
    emit archiveUpdated();
}

QVector<SpyEditRecord> SpyManager::fetchAllEditRecords(int64_t peerId) const {
    QMutexLocker locker(&m_mutex);
    if (peerId == 0) {
        return m_editedCache;
    }
    QVector<SpyEditRecord> filtered;
    for (const auto& r : m_editedCache) {
        if (r.peerId == peerId) {
            filtered.append(r);
        }
    }
    return filtered;
}

void SpyManager::deleteRecord(const QString& id, bool isDeletedMessage) {
    QMutexLocker locker(&m_mutex);
    if (isDeletedMessage) {
        for (int i = 0; i < m_deletedCache.size(); ++i) {
            if (m_deletedCache[i].id == id) {
                m_deletedMap.remove(m_deletedCache[i].id);
                m_deletedCache.removeAt(i);
                break;
            }
        }
    } else {
        for (int i = 0; i < m_editedCache.size(); ++i) {
            if (m_editedCache[i].id == id) {
                QString key = QString("%1_%2").arg(m_editedCache[i].peerId).arg(m_editedCache[i].messageId);
                if (m_editedMap.contains(key)) {
                    auto& list = m_editedMap[key];
                    for (int j = 0; j < list.size(); ++j) {
                        if (list[j].id == id) {
                            list.removeAt(j);
                            break;
                        }
                    }
                }
                m_editedCache.removeAt(i);
                break;
            }
        }
    }
    persist();
    emit archiveUpdated();
}

void SpyManager::clearAllData() {
    QMutexLocker locker(&m_mutex);
    m_deletedCache.clear();
    m_deletedMap.clear();
    m_editedCache.clear();
    m_editedMap.clear();
    QFile::remove(archiveFilePath());
    emit archiveUpdated();
}

void SpyManager::enforceTTL() {
    int ttlDays = Settings::instance().retentionDaysTTL();
    if (ttlDays <= 0) return;

    int64_t cutoff = QDateTime::currentSecsSinceEpoch() - (int64_t)(ttlDays * 86400);

    QMutexLocker locker(&m_mutex);
    int oldDel = m_deletedCache.size();
    int oldEdit = m_editedCache.size();

    QVector<SpyDeletedRecord> newDel;
    m_deletedMap.clear();
    for (const auto& r : m_deletedCache) {
        if (r.deletionTimestamp >= cutoff) {
            newDel.append(r);
            m_deletedMap[r.id] = r;
        }
    }
    m_deletedCache = newDel;

    QVector<SpyEditRecord> newEdit;
    m_editedMap.clear();
    for (const auto& r : m_editedCache) {
        if (r.timestamp >= cutoff) {
            newEdit.append(r);
            QString key = QString("%1_%2").arg(r.peerId).arg(r.messageId);
            m_editedMap[key].append(r);
        }
    }
    m_editedCache = newEdit;

    if (m_deletedCache.size() != oldDel || m_editedCache.size() != oldEdit) {
        persist();
        emit archiveUpdated();
    }
}

int64_t SpyManager::totalSizeBytes() const {
    QFile file(archiveFilePath());
    return file.size();
}

QString SpyManager::formattedArchiveSize() const {
    int64_t bytes = totalSizeBytes();
    if (bytes < 1024) return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024) return QString("%1 KB").arg(QString::number(bytes / 1024.0, 'f', 1));
    return QString("%1 MB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 1));
}

QByteArray SpyManager::exportArchiveJson() const {
    QMutexLocker locker(&m_mutex);
    QJsonObject root;
    QJsonArray delArr;
    for (const auto& r : m_deletedCache) delArr.append(r.toJson());
    root["deleted"] = delArr;

    QJsonArray editArr;
    for (const auto& r : m_editedCache) editArr.append(r.toJson());
    root["edited"] = editArr;

    root["exportedTimestamp"] = (qint64)QDateTime::currentSecsSinceEpoch();
    root["client"] = "LightGram Desktop";

    QJsonDocument doc(root);
    return doc.toJson(QJsonDocument::Indented);
}

bool SpyManager::importArchiveJson(const QByteArray& data) {
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return false;

    QJsonObject root = doc.object();
    QMutexLocker locker(&m_mutex);

    if (root.contains("deleted")) {
        QJsonArray delArr = root["deleted"].toArray();
        for (const auto& val : delArr) {
            SpyDeletedRecord r = SpyDeletedRecord::fromJson(val.toObject());
            if (!m_deletedMap.contains(r.id)) {
                m_deletedCache.append(r);
                m_deletedMap[r.id] = r;
            }
        }
    }

    if (root.contains("edited")) {
        QJsonArray editArr = root["edited"].toArray();
        for (const auto& val : editArr) {
            SpyEditRecord r = SpyEditRecord::fromJson(val.toObject());
            QString key = QString("%1_%2").arg(r.peerId).arg(r.messageId);
            m_editedCache.append(r);
            m_editedMap[key].append(r);
        }
    }

    persist();
    emit archiveUpdated();
    return true;
}

} // namespace LightGram
