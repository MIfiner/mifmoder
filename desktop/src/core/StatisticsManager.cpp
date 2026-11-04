#include "StatisticsManager.hpp"
#include "SpyManager.hpp"
#include "MediaVaultManager.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <algorithm>

namespace LightGram {

StatisticsManager& StatisticsManager::instance() {
    static StatisticsManager inst;
    return inst;
}

StatisticsManager::StatisticsManager() {
    load();
}

QString StatisticsManager::statsFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir dir(configDir);
    if (!dir.exists()) dir.mkpath(".");
    return dir.filePath("lightgram_stats.json");
}

void StatisticsManager::load() {
    QMutexLocker locker(&m_mutex);
    QFile file(statsFilePath());
    if (!file.open(QIODevice::ReadOnly)) return;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return;

    m_events.clear();
    QJsonArray arr = doc.array();
    for (const auto& val : arr) {
        m_events.append(EventRecord::fromJson(val.toObject()));
    }
}

void StatisticsManager::persist() {
    QFile file(statsFilePath());
    if (!file.open(QIODevice::WriteOnly)) return;

    QJsonArray arr;
    // Keep at most 20,000 events to maintain optimal performance
    int start = qMax(0, m_events.size() - 20000);
    for (int i = start; i < m_events.size(); ++i) {
        arr.append(m_events[i].toJson());
    }

    QJsonDocument doc(arr);
    file.write(doc.toJson(QJsonDocument::Compact));
}

void StatisticsManager::recordMessageEvent(bool isOutgoing, MediaType mediaType, int64_t peerId,
                                          const QString& chatTitle, const QString& peerType) {
    EventRecord ev;
    ev.timestamp = QDateTime::currentSecsSinceEpoch();
    ev.isOutgoing = isOutgoing;
    ev.mediaType = static_cast<int>(mediaType);
    ev.peerId = peerId;
    ev.chatTitle = chatTitle.isEmpty() ? "Chat" : chatTitle;
    ev.peerType = peerType.isEmpty() ? "user" : peerType;

    {
        QMutexLocker locker(&m_mutex);
        m_events.append(ev);
        persist();
    }
    emit statsUpdated();
}

StatisticsSnapshot StatisticsManager::getSnapshot(int periodDays) const {
    QMutexLocker locker(&m_mutex);
    StatisticsSnapshot snap;
    snap.periodDays = periodDays;
    snap.generatedTimestamp = QDateTime::currentSecsSinceEpoch();

    int64_t cutoff = 0;
    if (periodDays > 0) {
        cutoff = snap.generatedTimestamp - (int64_t)(periodDays * 86400);
    }

    snap.hourlyActivity.resize(24);
    snap.hourlyActivity.fill(0);

    int daysCount = (periodDays > 0) ? periodDays : 7;
    snap.dailyLabels.resize(daysCount);
    snap.dailyCounts.resize(daysCount);
    snap.dailyCounts.fill(0);

    QDateTime now = QDateTime::currentDateTime();
    for (int i = 0; i < daysCount; ++i) {
        QDateTime dt = now.addDays(-(daysCount - 1 - i));
        snap.dailyLabels[i] = dt.toString("dd.MM");
    }

    QMap<int64_t, int> peerCounts;
    QMap<int64_t, QString> peerTitles;
    QMap<int64_t, QString> peerTypes;
    QSet<int64_t> activePeers;

    for (const auto& ev : m_events) {
        if (ev.timestamp < cutoff) continue;

        snap.totalCount++;
        if (ev.isOutgoing) snap.sentCount++;
        else snap.receivedCount++;

        activePeers.insert(ev.peerId);
        peerCounts[ev.peerId]++;
        peerTitles[ev.peerId] = ev.chatTitle;
        peerTypes[ev.peerId] = ev.peerType;

        // Media counts
        MediaType mt = static_cast<MediaType>(ev.mediaType);
        if (mt == MediaType::Photo) snap.photosCount++;
        else if (mt == MediaType::Video) snap.videosCount++;
        else if (mt == MediaType::Circle) snap.circlesCount++;
        else if (mt == MediaType::Voice) snap.voiceCount++;
        else if (mt == MediaType::Document) snap.filesCount++;

        // Hourly breakdown
        QDateTime dt = QDateTime::fromSecsSinceEpoch(ev.timestamp);
        int h = dt.time().hour();
        if (h >= 0 && h < 24) snap.hourlyActivity[h]++;

        // Daily breakdown
        int daysAgo = dt.date().daysTo(now.date());
        if (daysAgo >= 0 && daysAgo < daysCount) {
            int idx = daysCount - 1 - daysAgo;
            snap.dailyCounts[idx]++;
        }
    }

    snap.activeChatsCount = activePeers.size();

    // Peak hour
    int maxHourVal = -1;
    int maxHourIdx = 0;
    for (int i = 0; i < 24; ++i) {
        if (snap.hourlyActivity[i] > maxHourVal) {
            maxHourVal = snap.hourlyActivity[i];
            maxHourIdx = i;
        }
    }
    snap.peakHour = QString("%1:00 - %2:00").arg(maxHourIdx, 2, 10, QChar('0')).arg((maxHourIdx + 1) % 24, 2, 10, QChar('0'));

    // Peak day
    int maxDayVal = -1;
    int maxDayIdx = 0;
    for (int i = 0; i < daysCount; ++i) {
        if (snap.dailyCounts[i] > maxDayVal) {
            maxDayVal = snap.dailyCounts[i];
            maxDayIdx = i;
        }
    }
    snap.peakDay = snap.dailyLabels.value(maxDayIdx, "N/A");

    // Average per day
    snap.avgPerDay = daysCount > 0 ? (double)snap.totalCount / (double)daysCount : (double)snap.totalCount;

    // Top Chats
    QVector<QPair<int64_t, int>> sortedPeers;
    for (auto it = peerCounts.constBegin(); it != peerCounts.constEnd(); ++it) {
        sortedPeers.append({it.key(), it.value()});
    }
    std::sort(sortedPeers.begin(), sortedPeers.end(), [](const auto& a, const auto& b) {
        return a.second > b.second;
    });

    int topLimit = qMin(sortedPeers.size(), 6);
    for (int i = 0; i < topLimit; ++i) {
        int64_t pid = sortedPeers[i].first;
        int count = sortedPeers[i].second;
        double pct = snap.totalCount > 0 ? (double)count / (double)snap.totalCount * 100.0 : 0.0;
        snap.topChats.append(TopChatStat{
            pid,
            peerTitles.value(pid, "Chat"),
            count,
            pct,
            peerTypes.value(pid, "user")
        });
    }

    // Spy Mode stats
    snap.savedDeletedCount = SpyManager::instance().fetchAllDeletedMessages().size();
    snap.savedEditsCount = SpyManager::instance().fetchAllEditRecords().size();

    // Media Vault stats
    snap.vaultItemsCount = MediaVaultManager::instance().fetchAllItems().size();
    snap.vaultStorageFormatted = MediaVaultManager::instance().formattedStorageSize();

    return snap;
}

QString StatisticsManager::exportReportText(int periodDays) const {
    StatisticsSnapshot s = getSnapshot(periodDays);
    QString periodStr = (periodDays == 7) ? "7 Days" : ((periodDays == 30) ? "30 Days" : "All Time");

    QString r;
    r += "========================================\n";
    r += "     LIGHTGRAM DESKTOP ANALYTICS        \n";
    r += "========================================\n";
    r += QString("Report Period: %1\n").arg(periodStr);
    r += QString("Generated:     %1\n\n").arg(QDateTime::fromSecsSinceEpoch(s.generatedTimestamp).toString("yyyy-MM-dd HH:mm:ss"));
    r += "--- MESSAGE OVERVIEW ---\n";
    r += QString("Total Messages:    %1\n").arg(s.totalCount);
    r += QString("Sent Messages:     %1\n").arg(s.sentCount);
    r += QString("Received Messages: %1\n").arg(s.receivedCount);
    r += QString("Active Dialogs:    %1\n\n").arg(s.activeChatsCount);
    r += "--- MEDIA BREAKDOWN ---\n";
    r += QString("Photos:            %1\n").arg(s.photosCount);
    r += QString("Videos:            %1\n").arg(s.videosCount);
    r += QString("Circles (1:1):     %1\n").arg(s.circlesCount);
    r += QString("Voice Notes:       %1\n").arg(s.voiceCount);
    r += QString("Documents & Files: %1\n\n").arg(s.filesCount);
    r += "--- PEAK ACTIVITY ---\n";
    r += QString("Peak Hour:         %1\n").arg(s.peakHour);
    r += QString("Peak Day:          %1\n").arg(s.peakDay);
    r += QString("Avg Messages/Day:  %1\n\n").arg(QString::number(s.avgPerDay, 'f', 1));
    r += "--- LIGHTGRAM VAULT & ARCHIVE ---\n";
    r += QString("Preserved Deleted: %1\n").arg(s.savedDeletedCount);
    r += QString("Preserved Edits:   %1\n").arg(s.savedEditsCount);
    r += QString("Media Vault Files: %1 (%2)\n\n").arg(s.vaultItemsCount).arg(s.vaultStorageFormatted);
    r += "--- TOP ACTIVE CHATS ---\n";
    for (int i = 0; i < s.topChats.size(); ++i) {
        const auto& c = s.topChats[i];
        r += QString("%1. %2: %3 msgs (%4%)\n")
            .arg(i + 1)
            .arg(c.title)
            .arg(c.messageCount)
            .arg(QString::number(c.percentage, 'f', 1));
    }
    r += "========================================\n";
    return r;
}

} // namespace LightGram
