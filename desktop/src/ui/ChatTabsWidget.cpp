#include "ChatTabsWidget.hpp"
#include "../core/ThemeEngine.hpp"
#include <QPainter>

namespace LightGram {

ChatTabsWidget::ChatTabsWidget(QWidget* parent) : QWidget(parent) {
    setFixedHeight(40);
    m_layout = new QHBoxLayout(this);
    m_layout->setContentsMargins(8, 4, 8, 4);
    m_layout->setSpacing(6);
    m_layout->addStretch();
}

void ChatTabsWidget::addOrSelectTab(int64_t peerId, const QString& title) {
    for (const auto& t : m_tabs) {
        if (t.peerId == peerId) {
            selectTab(peerId);
            return;
        }
    }

    ChatTabItem item;
    item.peerId = peerId;
    item.title = title;
    m_tabs.append(item);
    rebuildLayout();
    selectTab(peerId);
}

void ChatTabsWidget::closeTab(int64_t peerId) {
    int idx = -1;
    for (int i = 0; i < m_tabs.size(); ++i) {
        if (m_tabs[i].peerId == peerId) {
            idx = i;
            break;
        }
    }
    if (idx < 0) return;

    m_tabs.removeAt(idx);
    emit tabClosed(peerId);

    if (m_currentPeerId == peerId) {
        if (!m_tabs.isEmpty()) {
            int newIdx = qBound(0, idx, m_tabs.size() - 1);
            selectTab(m_tabs[newIdx].peerId);
        } else {
            m_currentPeerId = 0;
            emit tabSelected(0);
        }
    }
    rebuildLayout();
}

void ChatTabsWidget::selectTab(int64_t peerId) {
    m_currentPeerId = peerId;
    rebuildLayout();
    emit tabSelected(peerId);
}

void ChatTabsWidget::updateTabUnread(int64_t peerId, int unreadCount) {
    for (auto& t : m_tabs) {
        if (t.peerId == peerId) {
            t.unreadCount = unreadCount;
            break;
        }
    }
    rebuildLayout();
}

void ChatTabsWidget::rebuildLayout() {
    QLayoutItem* item;
    while ((item = m_layout->takeAt(0)) != nullptr) {
        if (item->widget()) delete item->widget();
        delete item;
    }

    const auto& theme = ThemeEngine::instance().currentTheme();
    QString accent = theme.primaryAccent.name();

    for (const auto& t : m_tabs) {
        bool isSel = (t.peerId == m_currentPeerId);

        QWidget* tab = new QWidget(this);
        QHBoxLayout* hl = new QHBoxLayout(tab);
        hl->setContentsMargins(12, 4, 8, 4);
        hl->setSpacing(8);

        QLabel* lbl = new QLabel(t.title, tab);
        lbl->setStyleSheet(QString("font-weight: %1; color: %2;")
                           .arg(isSel ? "bold" : "normal")
                           .arg(isSel ? accent : theme.textSecondary.name()));
        hl->addWidget(lbl);

        if (t.unreadCount > 0) {
            QLabel* unreadLbl = new QLabel(QString::number(t.unreadCount), tab);
            unreadLbl->setStyleSheet(QString(
                "background-color: %1; color: #000000; border-radius: 9px; padding: 1px 6px; font-size: 11px; font-weight: bold;"
            ).arg(accent));
            hl->addWidget(unreadLbl);
        }

        QPushButton* closeBtn = new QPushButton("×", tab);
        closeBtn->setFixedSize(18, 18);
        closeBtn->setStyleSheet(
            "QPushButton { border: none; background: transparent; color: #888888; font-size: 14px; font-weight: bold; border-radius: 9px; padding: 0px; margin: 0px; }"
            "QPushButton:hover { background: rgba(255, 255, 255, 0.15); color: #FFFFFF; }"
        );
        int64_t pid = t.peerId;
        connect(closeBtn, &QPushButton::clicked, [this, pid]() {
            closeTab(pid);
        });
        hl->addWidget(closeBtn);

        tab->setStyleSheet(QString(
            "QWidget { background-color: %1; border: 1px solid %2; border-radius: 10px; }"
        ).arg(isSel ? "rgba(255, 255, 255, 0.10)" : "rgba(255, 255, 255, 0.03)")
         .arg(isSel ? accent : "rgba(255, 255, 255, 0.08)"));

        // Click to select
        tab->setCursor(Qt::PointingHandCursor);
        tab->installEventFilter(this);

        m_layout->addWidget(tab);
    }

    m_layout->addStretch();
}

} // namespace LightGram
