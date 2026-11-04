#pragma once

#include <QWidget>
#include <QVBoxLayout>
#include <QScrollArea>
#include <QTextEdit>
#include <QPushButton>
#include <QLabel>
#include <QVector>
#include <cstdint>
#include "../core/Types.hpp"

namespace LightGram {

class ChatViewWidget : public QWidget {
    Q_OBJECT
public:
    explicit ChatViewWidget(QWidget* parent = nullptr);

    void loadChat(int64_t peerId, const QString& title);
    int64_t currentPeerId() const { return m_peerId; }

signals:
    void detachWindowRequested(int64_t peerId);
    void openMediaVaultRequested();
    void openCircleStudioRequested();

protected:
    void dragEnterEvent(QDragEnterEvent* event) override;
    void dropEvent(QDropEvent* event) override;

private slots:
    void onSendMessageClicked();
    void onAttachFileClicked();
    void onMessageReceived(const MessageItem& msg);
    void onMessageUpdated(const MessageItem& msg);

private:
    void setupUi();
    void renderTimeline();
    QWidget* createMessageBubbleWidget(const MessageItem& msg);

    int64_t m_peerId = 0;
    QString m_chatTitle;

    QLabel* m_headerTitle = nullptr;
    QLabel* m_headerStatus = nullptr;
    QPushButton* m_ghostBtn = nullptr;

    QScrollArea* m_scrollArea = nullptr;
    QWidget* m_timelineContainer = nullptr;
    QVBoxLayout* m_timelineLayout = nullptr;

    QTextEdit* m_inputEdit = nullptr;
    QPushButton* m_sendBtn = nullptr;
    QPushButton* m_attachBtn = nullptr;
    QPushButton* m_circleBtn = nullptr;
};

} // namespace LightGram
