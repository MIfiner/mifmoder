#pragma once

#include <QWidget>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QVector>
#include <cstdint>

namespace LightGram {

struct ChatTabItem {
    int64_t peerId = 0;
    QString title;
    int unreadCount = 0;
    QWidget* tabButton = nullptr;
};

class ChatTabsWidget : public QWidget {
    Q_OBJECT
public:
    explicit ChatTabsWidget(QWidget* parent = nullptr);

    void addOrSelectTab(int64_t peerId, const QString& title);
    void closeTab(int64_t peerId);
    void selectTab(int64_t peerId);
    void updateTabUnread(int64_t peerId, int unreadCount);
    int64_t currentPeerId() const { return m_currentPeerId; }

signals:
    void tabSelected(int64_t peerId);
    void tabClosed(int64_t peerId);

private:
    void rebuildLayout();

    QHBoxLayout* m_layout = nullptr;
    QVector<ChatTabItem> m_tabs;
    int64_t m_currentPeerId = 0;
};

} // namespace LightGram
