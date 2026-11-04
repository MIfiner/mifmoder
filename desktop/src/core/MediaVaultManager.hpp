#pragma once

#include "Types.hpp"
#include <QObject>
#include <QVector>
#include <QMap>
#include <QMutex>

namespace LightGram {

class MediaVaultManager : public QObject {
    Q_OBJECT
public:
    static MediaVaultManager& instance();

    void load();
    void persist();

    // Saving items
    bool saveToVault(const QString& sourceFilePath, const QString& fileName,
                     const QString& mediaType, int32_t messageId, int64_t peerId,
                     const QString& chatTitle, const QString& authorName);

    // Queries
    QVector<MediaVaultItem> fetchAllItems(const QString& filterType = "all",
                                          const QString& searchQuery = "") const;

    MediaVaultItem getItem(const QString& id) const;
    QString resolveItemAbsolutePath(const MediaVaultItem& item) const;

    // Actions
    void toggleFavorite(const QString& id);
    bool deleteItem(const QString& id);
    void clearVault(bool keepFavorites = true);
    bool exportItem(const QString& id, const QString& destinationPath) const;
    int batchExport(const QString& destinationFolder) const;

    // Storage
    int64_t totalStorageBytes() const;
    QString formattedStorageSize() const;

    void enforceRetentionTTL(int days);

signals:
    void vaultUpdated();
    void itemAdded(const MediaVaultItem& item);

private:
    MediaVaultManager();
    QString vaultDirectory() const;
    QString manifestPath() const;

    mutable QMutex m_mutex;
    QVector<MediaVaultItem> m_items;
    QMap<QString, MediaVaultItem> m_itemsMap;
};

} // namespace LightGram
