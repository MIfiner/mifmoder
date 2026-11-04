#pragma once

#include <QObject>
#include <QSet>
#include <QMutex>
#include <cstdint>

namespace LightGram {

class GhostController : public QObject {
    Q_OBJECT
public:
    static GhostController& instance();

    bool shouldSuppressReadHistory(int64_t peerId) const;
    void markPeerAsReadManually(int64_t peerId);
    void resetManualRead(int64_t peerId);

    bool shouldSuppressTyping(int64_t peerId) const;
    bool shouldSuppressStoryView() const;
    bool shouldSuppressOnlinePresence() const;

    // Checks if outgoing message sent by user in this chat should auto-mark as read
    bool handleOutgoingMessage(int64_t peerId);

signals:
    void peerReadStateUpdated(int64_t peerId, bool isRead);

private:
    GhostController();

    mutable QMutex m_mutex;
    QSet<int64_t> m_manuallyReadPeers;
};

} // namespace LightGram
