#pragma once

#include "Types.hpp"
#include <QObject>
#include <QVector>
#include <QMap>
#include <QDateTime>
#include <QMutex>

namespace LightGram {

class StatisticsManager : public QObject {
    Q_OBJECT
public:
    static StatisticsManager& instance();

    void load();
    void persist();

    void recordMessageEvent(bool isOutgoing, MediaType mediaType, int64_t peerId,
                            const QString& chatTitle, const QString& peerType);

    StatisticsSnapshot getSnapshot(int periodDays = 7) const;

    QString exportReportText(int periodDays = 7) const;

signals:
    void statsUpdated();

private:
    StatisticsManager();
    QString statsFilePath() const;

    struct EventRecord {
        int64_t timestamp = 0;
        bool isOutgoing = false;
        int mediaType = 0;
        int64_t peerId = 0;
        QString chatTitle;
        QString peerType;

        QJsonObject toJson() const {
            QJsonObject obj;
            obj["t"] = (qint64)timestamp;
            obj["out"] = isOutgoing;
            obj["m"] = mediaType;
            obj["pid"] = QString::number(peerId);
            obj["title"] = chatTitle;
            obj["ptype"] = peerType;
            return obj;
        }

        static EventRecord fromJson(const QJsonObject& obj) {
            EventRecord e;
            e.timestamp = obj["t"].toVariant().toLongLong();
            e.isOutgoing = obj["out"].toBool();
            e.mediaType = obj["m"].toInt();
            e.peerId = obj["pid"].toString().toLongLong();
            e.chatTitle = obj["title"].toString();
            e.peerType = obj["ptype"].toString();
            return e;
        }
    };

    mutable QMutex m_mutex;
    QVector<EventRecord> m_events;
};

} // namespace LightGram
