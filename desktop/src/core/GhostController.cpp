#include "GhostController.hpp"
#include "Settings.hpp"

namespace LightGram {

GhostController& GhostController::instance() {
    static GhostController inst;
    return inst;
}

GhostController::GhostController() {
}

bool GhostController::shouldSuppressReadHistory(int64_t peerId) const {
    if (!Settings::instance().isGhostModeEnabled()) {
        return false;
    }
    if (!Settings::instance().suppressReadHistory()) {
        return false;
    }
    QMutexLocker locker(&m_mutex);
    if (m_manuallyReadPeers.contains(peerId)) {
        return false;
    }
    return true;
}

void GhostController::markPeerAsReadManually(int64_t peerId) {
    {
        QMutexLocker locker(&m_mutex);
        m_manuallyReadPeers.insert(peerId);
    }
    emit peerReadStateUpdated(peerId, true);
}

void GhostController::resetManualRead(int64_t peerId) {
    {
        QMutexLocker locker(&m_mutex);
        m_manuallyReadPeers.remove(peerId);
    }
    emit peerReadStateUpdated(peerId, false);
}

bool GhostController::shouldSuppressTyping(int64_t peerId) const {
    Q_UNUSED(peerId);
    if (!Settings::instance().isGhostModeEnabled()) {
        return false;
    }
    return Settings::instance().suppressTyping();
}

bool GhostController::shouldSuppressStoryView() const {
    if (!Settings::instance().isGhostModeEnabled()) {
        return false;
    }
    return Settings::instance().suppressStoryViews();
}

bool GhostController::shouldSuppressOnlinePresence() const {
    return Settings::instance().isGhostModeEnabled();
}

bool GhostController::handleOutgoingMessage(int64_t peerId) {
    if (Settings::instance().isGhostModeEnabled() && Settings::instance().markAsReadOnReply()) {
        markPeerAsReadManually(peerId);
        return true;
    }
    return false;
}

} // namespace LightGram
