#pragma once

#include "Types.hpp"
#include <QObject>
#include <QVector>
#include <QMap>
#include <QTcpSocket>
#include <QElapsedTimer>

namespace LightGram {

enum class ConnectionState {
    Disconnected,
    Connecting,
    WaitingForPhoneNumber,
    WaitingForCode,
    WaitingForPassword, // 2FA
    Ready
};

class TelegramClient : public QObject {
    Q_OBJECT
public:
    static TelegramClient& instance();

    ConnectionState connectionState() const { return m_state; }
    bool isAuthorized() const { return m_state == ConnectionState::Ready; }

    // Authorization
    void startConnection();
    void sendPhoneNumber(const QString& phoneNumber);
    void sendAuthCode(const QString& code);
    void sendPassword(const QString& password);
    void requestQrCode();
    void logOut();

    // Accounts
    int activeAccountIndex() const { return m_activeAccountIndex; }
    void switchAccount(int index);
    QVector<QString> availableAccounts() const;

    // Chat queries
    QVector<ChatSummary> getChats(const QString& folderId = "all") const;
    ChatSummary getChat(int64_t peerId) const;
    QVector<MessageItem> getMessages(int64_t peerId, int limit = 50) const;

    // Actions
    void sendMessage(int64_t peerId, const QString& text, int32_t replyToId = 0);
    void sendMediaFile(int64_t peerId, const QString& filePath, const QString& caption = QString());
    void markAsRead(int64_t peerId);
    void deleteMessage(int64_t peerId, int32_t messageId, bool revokeForAll = true);

    // Diagnostics: Ping Telegram Data Centers (Miami, Amsterdam, Singapore)
    void pingDataCenters();

    // Simulation & demo injection for testing all features
    void injectSimulatedIncomingMessage(int64_t peerId, const QString& senderName, const QString& text);
    void injectSimulatedRemoteDelete(int64_t peerId, int32_t messageId);
    void injectSimulatedRemoteEdit(int64_t peerId, int32_t messageId, const QString& newText);

signals:
    void stateChanged(ConnectionState state);
    void authError(const QString& errorMessage);
    void qrCodeGenerated(const QString& qrDataUrl);
    void chatsUpdated();
    void messageReceived(const MessageItem& message);
    void messageUpdated(const MessageItem& message);
    void messageDeleted(int64_t peerId, int32_t messageId);
    void dcPingResult(int dcId, const QString& name, const QString& ip, int rttMs, bool ok);

private slots:
    void handleSocketConnected();
    void handleSocketError();

private:
    TelegramClient();
    void populateInitialChats();

    ConnectionState m_state = ConnectionState::Ready; // Default to Ready for instant usability
    int m_activeAccountIndex = 0;
    QString m_currentPhone;

    QMap<int64_t, ChatSummary> m_chats;
    QMap<int64_t, QVector<MessageItem>> m_messages;

    struct DcTarget {
        int id;
        QString name;
        QString host;
        quint16 port;
    };
    QVector<DcTarget> m_dataCenters;
};

} // namespace LightGram
