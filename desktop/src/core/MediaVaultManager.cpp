#include "MediaVaultManager.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>

namespace LightGram {

MediaVaultManager& MediaVaultManager::instance() {
    static MediaVaultManager inst;
    return inst;
}

MediaVaultManager::MediaVaultManager() {
    load();
}

QString MediaVaultManager::vaultDirectory() const {
    QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(appData);
    QString path = dir.filePath("MediaVault");
    QDir vaultDir(path);
    if (!vaultDir.exists()) {
        vaultDir.mkpath(".");
    }
    return path;
}

QString MediaVaultManager::manifestPath() const {
    QDir dir(vaultDirectory());
    return dir.filePath("manifest.json");
}

void MediaVaultManager::load() {
    QMutexLocker locker(&m_mutex);
    QFile file(manifestPath());
    if (!file.open(QIODevice::ReadOnly)) return;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return;

    m_items.clear();
    m_itemsMap.clear();
    QJsonArray arr = doc.array();
    for (const auto& val : arr) {
        MediaVaultItem it = MediaVaultItem::fromJson(val.toObject());
        m_items.append(it);
        m_itemsMap[it.id] = it;
    }
}

void MediaVaultManager::persist() {
    QFile file(manifestPath());
    if (!file.open(QIODevice::WriteOnly)) return;

    QJsonArray arr;
    for (const auto& it : m_items) {
        arr.append(it.toJson());
    }

    QJsonDocument doc(arr);
    file.write(doc.toJson(QJsonDocument::Compact));
}

bool MediaVaultManager::saveToVault(const QString& sourceFilePath, const QString& fileName,
                                    const QString& mediaType, int32_t messageId, int64_t peerId,
                                    const QString& chatTitle, const QString& authorName) {
    QFileInfo srcInfo(sourceFilePath);
    if (!srcInfo.exists()) {
        return false;
    }

    QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QString ext = srcInfo.suffix();
    QString safeFileName = fileName.isEmpty() ? srcInfo.fileName() : fileName;
    QString storedName = QString("%1_%2").arg(id).arg(safeFileName);

    QDir vault(vaultDirectory());
    QString destPath = vault.filePath(storedName);

    if (!QFile::copy(sourceFilePath, destPath)) {
        return false;
    }

    MediaVaultItem item;
    item.id = id;
    item.messageId = messageId;
    item.peerId = peerId;
    item.mediaType = mediaType;
    item.fileName = safeFileName;
    item.relativePath = storedName;
    item.fileSize = srcInfo.size();
    item.savedTimestamp = QDateTime::currentSecsSinceEpoch();
    item.isFavorite = false;
    item.senderName = authorName.isEmpty() ? "Unknown" : authorName;
    item.chatTitle = chatTitle.isEmpty() ? "Chat" : chatTitle;

    {
        QMutexLocker locker(&m_mutex);
        m_items.prepend(item);
        m_itemsMap[item.id] = item;
        persist();
    }

    emit itemAdded(item);
    emit vaultUpdated();
    return true;
}

QVector<MediaVaultItem> MediaVaultManager::fetchAllItems(const QString& filterType,
                                                        const QString& searchQuery) const {
    QMutexLocker locker(&m_mutex);
    QVector<MediaVaultItem> results;
    QString q = searchQuery.trimmed().toLower();

    for (const auto& it : m_items) {
        if (filterType == "favorites" && !it.isFavorite) continue;
        if (filterType != "all" && filterType != "favorites" && it.mediaType != filterType) continue;

        if (!q.isEmpty()) {
            bool matches = it.fileName.toLower().contains(q) ||
                           it.senderName.toLower().contains(q) ||
                           it.chatTitle.toLower().contains(q);
            if (!matches) continue;
        }

        results.append(it);
    }
    return results;
}

MediaVaultItem MediaVaultManager::getItem(const QString& id) const {
    QMutexLocker locker(&m_mutex);
    return m_itemsMap.value(id);
}

QString MediaVaultManager::resolveItemAbsolutePath(const MediaVaultItem& item) const {
    QDir vault(vaultDirectory());
    return vault.filePath(item.relativePath);
}

void MediaVaultManager::toggleFavorite(const QString& id) {
    QMutexLocker locker(&m_mutex);
    if (!m_itemsMap.contains(id)) return;

    bool current = m_itemsMap[id].isFavorite;
    m_itemsMap[id].isFavorite = !current;

    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].id == id) {
            m_items[i].isFavorite = !current;
            break;
        }
    }
    persist();
    emit vaultUpdated();
}

bool MediaVaultManager::deleteItem(const QString& id) {
    QString relPath;
    {
        QMutexLocker locker(&m_mutex);
        if (!m_itemsMap.contains(id)) return false;
        relPath = m_itemsMap[id].relativePath;
        m_itemsMap.remove(id);

        for (int i = 0; i < m_items.size(); ++i) {
            if (m_items[i].id == id) {
                m_items.removeAt(i);
                break;
            }
        }
        persist();
    }

    QDir vault(vaultDirectory());
    QFile::remove(vault.filePath(relPath));

    emit vaultUpdated();
    return true;
}

void MediaVaultManager::clearVault(bool keepFavorites) {
    QVector<QString> toDeleteFiles;
    {
        QMutexLocker locker(&m_mutex);
        QVector<MediaVaultItem> remaining;
        for (const auto& it : m_items) {
            if (keepFavorites && it.isFavorite) {
                remaining.append(it);
            } else {
                toDeleteFiles.append(it.relativePath);
            }
        }
        m_items = remaining;
        m_itemsMap.clear();
        for (const auto& it : m_items) {
            m_itemsMap[it.id] = it;
        }
        persist();
    }

    QDir vault(vaultDirectory());
    for (const auto& f : toDeleteFiles) {
        QFile::remove(vault.filePath(f));
    }

    emit vaultUpdated();
}

bool MediaVaultManager::exportItem(const QString& id, const QString& destinationPath) const {
    MediaVaultItem it = getItem(id);
    if (it.id.isEmpty()) return false;

    QString src = resolveItemAbsolutePath(it);
    return QFile::copy(src, destinationPath);
}

int MediaVaultManager::batchExport(const QString& destinationFolder) const {
    QDir dest(destinationFolder);
    if (!dest.exists()) dest.mkpath(".");

    QMutexLocker locker(&m_mutex);
    int count = 0;
    for (const auto& it : m_items) {
        QString src = resolveItemAbsolutePath(it);
        QString target = dest.filePath(it.fileName);
        if (QFile::exists(target)) {
            target = dest.filePath(QString("%1_%2").arg(it.id.left(6)).arg(it.fileName));
        }
        if (QFile::copy(src, target)) {
            count++;
        }
    }
    return count;
}

int64_t MediaVaultManager::totalStorageBytes() const {
    QMutexLocker locker(&m_mutex);
    int64_t total = 0;
    for (const auto& it : m_items) {
        total += it.fileSize;
    }
    return total;
}

QString MediaVaultManager::formattedStorageSize() const {
    double bytes = totalStorageBytes();
    if (bytes < 1024) return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024) return QString("%1 KB").arg(QString::number(bytes / 1024.0, 'f', 1));
    if (bytes < 1024 * 1024 * 1024) return QString("%1 MB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 1));
    return QString("%1 GB").arg(QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2));
}

void MediaVaultManager::enforceRetentionTTL(int days) {
    if (days <= 0) return;
    int64_t cutoff = QDateTime::currentSecsSinceEpoch() - (int64_t)(days * 86400);

    QVector<QString> toDeleteFiles;
    {
        QMutexLocker locker(&m_mutex);
        QVector<MediaVaultItem> remaining;
        for (const auto& it : m_items) {
            if (it.isFavorite || it.savedTimestamp >= cutoff) {
                remaining.append(it);
            } else {
                toDeleteFiles.append(it.relativePath);
            }
        }
        m_items = remaining;
        m_itemsMap.clear();
        for (const auto& it : m_items) m_itemsMap[it.id] = it;
        persist();
    }

    QDir vault(vaultDirectory());
    for (const auto& f : toDeleteFiles) {
        QFile::remove(vault.filePath(f));
    }
    emit vaultUpdated();
}

} // namespace LightGram
