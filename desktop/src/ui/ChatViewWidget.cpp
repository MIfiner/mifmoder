#include "ChatViewWidget.hpp"
#include "../core/TelegramClient.hpp"
#include "../core/ThemeEngine.hpp"
#include "../core/GhostController.hpp"
#include "../core/SpyManager.hpp"
#include "../core/MediaVaultManager.hpp"
#include "../core/NotesManager.hpp"
#include "../core/Settings.hpp"
#include "../core/Localization.hpp"
#include <QHBoxLayout>
#include <QFileDialog>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QMenu>
#include <QMessageBox>
#include <QDateTime>
#include <QScrollBar>
#include <QApplication>
#include <QClipboard>
#include <QTimer>

namespace LightGram {

ChatViewWidget::ChatViewWidget(QWidget* parent) : QWidget(parent) {
    setAcceptDrops(true);
    setupUi();

    connect(&TelegramClient::instance(), &TelegramClient::messageReceived, this, &ChatViewWidget::onMessageReceived);
    connect(&TelegramClient::instance(), &TelegramClient::messageUpdated, this, &ChatViewWidget::onMessageUpdated);
}

void ChatViewWidget::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(0, 0, 0, 0);
    mainLayout->setSpacing(0);

    // 1. Chat Header Bar
    QWidget* headerBar = new QWidget(this);
    headerBar->setFixedHeight(56);
    headerBar->setStyleSheet("background: rgba(255, 255, 255, 0.04); border-bottom: 1px solid rgba(255, 255, 255, 0.08);");

    QHBoxLayout* headerLayout = new QHBoxLayout(headerBar);
    headerLayout->setContentsMargins(16, 8, 16, 8);

    QVBoxLayout* titlesLayout = new QVBoxLayout();
    titlesLayout->setSpacing(2);

    m_headerTitle = new QLabel("Select a chat", headerBar);
    m_headerTitle->setStyleSheet("font-size: 15px; font-weight: bold; color: #FFFFFF;");
    titlesLayout->addWidget(m_headerTitle);

    m_headerStatus = new QLabel("Offline", headerBar);
    m_headerStatus->setStyleSheet("font-size: 11px; color: #888888;");
    titlesLayout->addWidget(m_headerStatus);
    headerLayout->addLayout(titlesLayout);

    headerLayout->addStretch();

    // Ghost Mode quick toggle button
    m_ghostBtn = new QPushButton("👻 Ghost", headerBar);
    m_ghostBtn->setCheckable(true);
    m_ghostBtn->setChecked(Settings::instance().isGhostModeEnabled());
    m_ghostBtn->setStyleSheet(
        "QPushButton { font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 8px; border: 1px solid #EDB400; color: #EDB400; background: transparent; }"
        "QPushButton:checked { background: #EDB400; color: #000000; }"
    );
    connect(m_ghostBtn, &QPushButton::toggled, [](bool checked) {
        Settings::instance().setGhostModeEnabled(checked);
    });
    headerLayout->addWidget(m_ghostBtn);

    // Video note / Circle studio button
    m_circleBtn = new QPushButton("⭕ Circle", headerBar);
    m_circleBtn->setStyleSheet(
        "QPushButton { font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.15); color: #FFFFFF; background: rgba(255,255,255,0.06); }"
        "QPushButton:hover { background: rgba(255,255,255,0.15); }"
    );
    connect(m_circleBtn, &QPushButton::clicked, this, &ChatViewWidget::openCircleStudioRequested);
    headerLayout->addWidget(m_circleBtn);

    // Detach window button (Multi-Window)
    QPushButton* detachBtn = new QPushButton("🗗", headerBar);
    detachBtn->setFixedSize(32, 32);
    detachBtn->setToolTip(trL("Desktop_DetachWindow"));
    detachBtn->setStyleSheet("QPushButton { border-radius: 16px; background: rgba(255,255,255,0.06); font-size: 14px; } QPushButton:hover { background: rgba(255,255,255,0.15); }");
    connect(detachBtn, &QPushButton::clicked, [this]() {
        if (m_peerId != 0) emit detachWindowRequested(m_peerId);
    });
    headerLayout->addWidget(detachBtn);

    mainLayout->addWidget(headerBar);

    // 2. Timeline Scroll Area
    m_scrollArea = new QScrollArea(this);
    m_scrollArea->setWidgetResizable(true);
    m_scrollArea->setStyleSheet("QScrollArea { background: transparent; border: none; }");

    m_timelineContainer = new QWidget(m_scrollArea);
    m_timelineContainer->setStyleSheet("background: transparent;");
    m_timelineLayout = new QVBoxLayout(m_timelineContainer);
    m_timelineLayout->setContentsMargins(20, 16, 20, 16);
    m_timelineLayout->setSpacing(12);
    m_timelineLayout->addStretch();

    m_scrollArea->setWidget(m_timelineContainer);
    mainLayout->addWidget(m_scrollArea, 1);

    // 3. Composer Bar
    QWidget* composerBar = new QWidget(this);
    composerBar->setStyleSheet("background: rgba(255, 255, 255, 0.04); border-top: 1px solid rgba(255, 255, 255, 0.08);");
    QHBoxLayout* composerLayout = new QHBoxLayout(composerBar);
    composerLayout->setContentsMargins(16, 10, 16, 10);
    composerLayout->setSpacing(10);

    m_attachBtn = new QPushButton("📎", composerBar);
    m_attachBtn->setFixedSize(36, 36);
    m_attachBtn->setToolTip("Attach File or Media (or drag & drop)");
    m_attachBtn->setStyleSheet("QPushButton { font-size: 16px; border-radius: 18px; background: rgba(255, 255, 255, 0.08); } QPushButton:hover { background: rgba(255, 255, 255, 0.18); }");
    connect(m_attachBtn, &QPushButton::clicked, this, &ChatViewWidget::onAttachFileClicked);
    composerLayout->addWidget(m_attachBtn);

    m_inputEdit = new QTextEdit(composerBar);
    m_inputEdit->setFixedHeight(40);
    m_inputEdit->setPlaceholderText("Write a message...");
    m_inputEdit->setStyleSheet(
        "QTextEdit { background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.1); "
        "border-radius: 12px; padding: 6px 12px; font-size: 13px; color: #FFFFFF; }"
        "QTextEdit:focus { border: 1px solid #EDB400; }"
    );
    composerLayout->addWidget(m_inputEdit, 1);

    m_sendBtn = new QPushButton("➤", composerBar);
    m_sendBtn->setFixedSize(36, 36);
    m_sendBtn->setToolTip("Send Message (Enter)");
    m_sendBtn->setStyleSheet(
        "QPushButton { font-size: 16px; border-radius: 18px; background: #EDB400; color: #000000; font-weight: bold; } "
        "QPushButton:hover { background: #FFC700; }"
    );
    connect(m_sendBtn, &QPushButton::clicked, this, &ChatViewWidget::onSendMessageClicked);
    composerLayout->addWidget(m_sendBtn);

    mainLayout->addWidget(composerBar);
}

void ChatViewWidget::loadChat(int64_t peerId, const QString& title) {
    m_peerId = peerId;
    m_chatTitle = title;

    if (m_headerTitle) m_headerTitle->setText(title);
    ChatSummary chat = TelegramClient::instance().getChat(peerId);
    if (m_headerStatus) {
        if (chat.isOnline) {
            m_headerStatus->setText("Online");
            m_headerStatus->setStyleSheet("font-size: 11px; color: #34C759; font-weight: 500;");
        } else {
            m_headerStatus->setText(chat.type == PeerType::Channel ? "Channel" : (chat.type == PeerType::Group ? "Group" : "Offline"));
            m_headerStatus->setStyleSheet("font-size: 11px; color: #888888;");
        }
    }

    renderTimeline();

    // Mark as read only if ghost mode doesn't suppress it
    TelegramClient::instance().markAsRead(peerId);
}

void ChatViewWidget::renderTimeline() {
    QLayoutItem* item;
    while ((item = m_timelineLayout->takeAt(0)) != nullptr) {
        if (item->widget()) delete item->widget();
        delete item;
    }
    m_timelineLayout->addStretch();

    if (m_peerId == 0) return;

    auto messages = TelegramClient::instance().getMessages(m_peerId);
    for (const auto& msg : messages) {
        QWidget* bubble = createMessageBubbleWidget(msg);
        m_timelineLayout->addWidget(bubble);
    }

    QScrollBar* vbar = m_scrollArea->verticalScrollBar();
    QTimer::singleShot(20, [vbar]() {
        if (vbar) vbar->setValue(vbar->maximum());
    });
}

QWidget* ChatViewWidget::createMessageBubbleWidget(const MessageItem& msg) {
    QWidget* rowWidget = new QWidget(m_timelineContainer);
    QHBoxLayout* rowLayout = new QHBoxLayout(rowWidget);
    rowLayout->setContentsMargins(0, 2, 0, 2);

    const auto& theme = ThemeEngine::instance().currentTheme();

    QWidget* bubble = new QWidget(rowWidget);
    QVBoxLayout* bubbleLayout = new QVBoxLayout(bubble);
    bubbleLayout->setContentsMargins(12, 10, 12, 10);
    bubbleLayout->setSpacing(4);

    // Deleted Message Header
    if (msg.isDeleted) {
        QLabel* delBadge = new QLabel(trL("Badge_Deleted"), bubble);
        delBadge->setStyleSheet(
            "background-color: #FF3B30; color: #FFFFFF; font-size: 10px; font-weight: bold; "
            "border-radius: 6px; padding: 2px 6px;"
        );
        bubbleLayout->addWidget(delBadge);
    }

    // Edited Message Banner
    if (!msg.editRevisions.isEmpty()) {
        const auto& rev = msg.editRevisions.last();
        QLabel* editBadge = new QLabel(QString("%1 (Rev %2)").arg(trL("Badge_Edited")).arg(rev.revision), bubble);
        editBadge->setStyleSheet(
            "background-color: #EDB400; color: #000000; font-size: 10px; font-weight: bold; "
            "border-radius: 6px; padding: 2px 6px;"
        );
        bubbleLayout->addWidget(editBadge);

        QLabel* prevTextLbl = new QLabel(QString("Was: \"%1\"").arg(rev.previousText), bubble);
        prevTextLbl->setStyleSheet("font-size: 11px; color: #EDB400; font-style: italic;");
        bubbleLayout->addWidget(prevTextLbl);
    }

    // Author name (in groups)
    if (!msg.isOutgoing && !msg.senderName.isEmpty()) {
        QLabel* authorLbl = new QLabel(msg.senderName, bubble);
        authorLbl->setStyleSheet(QString("font-size: 11px; font-weight: bold; color: %1;").arg(theme.primaryAccent.name()));
        bubbleLayout->addWidget(authorLbl);
    }

    // Text Content
    if (!msg.text.isEmpty()) {
        QLabel* textLbl = new QLabel(msg.text, bubble);
        textLbl->setWordWrap(true);
        textLbl->setTextInteractionFlags(Qt::TextSelectableByMouse);
        textLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(msg.isOutgoing ? theme.outgoingText.name() : theme.textPrimary.name()));
        bubbleLayout->addWidget(textLbl);
    }

    // Media attachment indicator
    if (msg.mediaType != MediaType::None) {
        QWidget* mediaCard = new QWidget(bubble);
        QHBoxLayout* ml = new QHBoxLayout(mediaCard);
        ml->setContentsMargins(8, 6, 8, 6);
        ml->setSpacing(8);

        QLabel* icon = new QLabel("📄", mediaCard);
        if (msg.mediaType == MediaType::Photo) icon->setText("🖼");
        else if (msg.mediaType == MediaType::Video) icon->setText("🎥");
        else if (msg.mediaType == MediaType::Circle) icon->setText("⭕");
        else if (msg.mediaType == MediaType::Voice) icon->setText("🎙");
        icon->setStyleSheet("font-size: 18px;");
        ml->addWidget(icon);

        QVBoxLayout* mvl = new QVBoxLayout();
        mvl->setSpacing(2);
        QLabel* mtitle = new QLabel(msg.mediaLocalPath.isEmpty() ? "Media Attachment" : QFileInfo(msg.mediaLocalPath).fileName(), mediaCard);
        mtitle->setStyleSheet("font-weight: 600; font-size: 12px;");
        mvl->addWidget(mtitle);

        QLabel* msize = new QLabel(QString("%1 KB").arg(msg.mediaSizeBytes / 1024), mediaCard);
        msize->setStyleSheet("font-size: 10px; color: #888888;");
        mvl->addWidget(msize);
        ml->addLayout(mvl);

        QPushButton* vaultSaveBtn = new QPushButton("🛡 Vault", mediaCard);
        vaultSaveBtn->setStyleSheet("QPushButton { font-size: 11px; padding: 2px 8px; border-radius: 6px; background: rgba(237,180,0,0.25); color: #EDB400; border: 1px solid #EDB400; }");
        QString path = msg.mediaLocalPath;
        QString name = QFileInfo(path).fileName();
        QString typeStr = (msg.mediaType == MediaType::Photo) ? "photo" : ((msg.mediaType == MediaType::Video) ? "video" : "file");
        int32_t mid = msg.id;
        int64_t pid = msg.peerId;
        QString cTitle = m_chatTitle;
        QString aName = msg.senderName;
        connect(vaultSaveBtn, &QPushButton::clicked, [path, name, typeStr, mid, pid, cTitle, aName]() {
            MediaVaultManager::instance().saveToVault(path, name, typeStr, mid, pid, cTitle, aName);
            QMessageBox::information(nullptr, "Media Vault", "File successfully saved into LightGram Media Vault!");
        });
        ml->addWidget(vaultSaveBtn);

        mediaCard->setStyleSheet("background: rgba(0,0,0,0.2); border-radius: 8px; border: 1px solid rgba(255,255,255,0.08);");
        bubbleLayout->addWidget(mediaCard);
    }

    // Time & Status
    QHBoxLayout* timeLayout = new QHBoxLayout();
    timeLayout->addStretch();
    QDateTime dt = QDateTime::fromSecsSinceEpoch(msg.timestamp);
    QLabel* timeLbl = new QLabel(dt.toString("HH:mm"), bubble);
    timeLbl->setStyleSheet("font-size: 10px; color: #888888;");
    timeLayout->addWidget(timeLbl);

    if (msg.isOutgoing) {
        QLabel* checkLbl = new QLabel("✓✓", bubble);
        checkLbl->setStyleSheet(QString("font-size: 10px; color: %1;").arg(theme.outgoingText.name()));
        timeLayout->addWidget(checkLbl);
    }
    bubbleLayout->addLayout(timeLayout);

    // Styling according to status
    int r = theme.cornerRadius;
    if (msg.isDeleted) {
        // Red outline & Crimson surface
        bubble->setStyleSheet(QString(
            "QWidget { background-color: #2C1416; border: 1.5px solid #FF3B30; border-radius: %1px; }"
        ).arg(r));
    } else if (!msg.editRevisions.isEmpty()) {
        // Amber outline & Dark amber surface
        bubble->setStyleSheet(QString(
            "QWidget { background-color: #2B2310; border: 1.5px solid #EDB400; border-radius: %1px; }"
        ).arg(r));
    } else if (msg.isOutgoing) {
        bubble->setStyleSheet(QString(
            "QWidget { background-color: %1; border-radius: %2px; }"
        ).arg(theme.outgoingBubble.name()).arg(r));
    } else {
        bubble->setStyleSheet(QString(
            "QWidget { background-color: %1; border: 1px solid %2; border-radius: %3px; }"
        ).arg(theme.incomingBubble.name()).arg(theme.borderGraphite.name()).arg(r));
    }

    bubble->setMaximumWidth(480);

    // Context Menu on message bubble
    bubble->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(bubble, &QWidget::customContextMenuRequested, [this, msg, bubble](const QPoint& pt) {
        QMenu menu(bubble);
        menu.addAction("📋 " + trL("Copy"), [msg]() {
            QApplication::clipboard()->setText(msg.text);
        });

        menu.addAction("📝 " + trL("Notes_SaveFromChat"), [this, msg]() {
            NotesManager::instance().addNote(m_chatTitle + " Note", msg.text, "#EDB400", msg.peerId, msg.id);
            QMessageBox::information(this, "Notes", "Message saved into Personal Notes!");
        });

        menu.addAction("⏰ Set Reminder", [this, msg]() {
            int64_t inOneHour = QDateTime::currentSecsSinceEpoch() + 3600;
            NotesManager::instance().addReminder(msg.peerId, msg.id, msg.text, inOneHour, m_chatTitle);
            QMessageBox::information(this, "Reminders", "Reminder scheduled for 1 hour from now!");
        });

        if (msg.mediaType != MediaType::None && !msg.mediaLocalPath.isEmpty()) {
            menu.addAction("🛡 " + trL("MediaVault_SaveToVault"), [this, msg]() {
                MediaVaultManager::instance().saveToVault(msg.mediaLocalPath, QFileInfo(msg.mediaLocalPath).fileName(),
                                                          "file", msg.id, msg.peerId, m_chatTitle, msg.senderName);
                QMessageBox::information(this, "Media Vault", "Saved to Media Vault!");
            });
        }

        if (msg.isDeleted) {
            menu.addAction("ℹ️ Deletion Details", [this, msg]() {
                QString info = QString("Chat: %1\nAuthor: %2\nSent: %3\nDeleted: %4\n\nOriginal Text:\n%5")
                                   .arg(m_chatTitle)
                                   .arg(msg.senderName)
                                   .arg(QDateTime::fromSecsSinceEpoch(msg.timestamp).toString())
                                   .arg(QDateTime::fromSecsSinceEpoch(msg.deletionTimestamp).toString())
                                   .arg(msg.text);
                QMessageBox::information(this, "Deleted Message Record", info);
            });
        }

        if (!msg.editRevisions.isEmpty()) {
            menu.addAction("🟡 Revision History", [this, msg]() {
                QString info = QString("Total revisions: %1\n\n").arg(msg.editRevisions.size());
                for (const auto& r : msg.editRevisions) {
                    info += QString("Rev %1 (%2):\nWas: \"%3\"\nNow: \"%4\"\n\n")
                                .arg(r.revision)
                                .arg(QDateTime::fromSecsSinceEpoch(r.timestamp).toString("HH:mm:ss"))
                                .arg(r.previousText)
                                .arg(r.newText);
                }
                QMessageBox::information(this, "Revision Timeline", info);
            });
        }

        menu.addSeparator();
        menu.addAction("🗑 Delete Locally", [this, msg]() {
            TelegramClient::instance().deleteMessage(msg.peerId, msg.id, false);
            renderTimeline();
        });

        menu.exec(bubble->mapToGlobal(pt));
    });

    if (msg.isOutgoing) {
        rowLayout->addStretch();
        rowLayout->addWidget(bubble);
    } else {
        rowLayout->addWidget(bubble);
        rowLayout->addStretch();
    }

    return rowWidget;
}

void ChatViewWidget::onSendMessageClicked() {
    if (m_peerId == 0 || !m_inputEdit) return;

    QString text = m_inputEdit->toPlainText().trimmed();
    if (text.isEmpty()) return;

    TelegramClient::instance().sendMessage(m_peerId, text);
    m_inputEdit->clear();
    renderTimeline();
}

void ChatViewWidget::onAttachFileClicked() {
    if (m_peerId == 0) return;

    QString file = QFileDialog::getOpenFileName(this, "Select File to Send", QDir::homePath(), "All Files (*.*)");
    if (!file.isEmpty()) {
        TelegramClient::instance().sendMediaFile(m_peerId, file);
        renderTimeline();
    }
}

void ChatViewWidget::onMessageReceived(const MessageItem& msg) {
    if (msg.peerId == m_peerId) {
        renderTimeline();
    }
}

void ChatViewWidget::onMessageUpdated(const MessageItem& msg) {
    if (msg.peerId == m_peerId) {
        renderTimeline();
    }
}

void ChatViewWidget::dragEnterEvent(QDragEnterEvent* event) {
    if (event->mimeData()->hasUrls()) {
        event->acceptProposedAction();
    }
}

void ChatViewWidget::dropEvent(QDropEvent* event) {
    if (m_peerId == 0) return;
    const QMimeData* mime = event->mimeData();
    if (mime->hasUrls()) {
        for (const QUrl& url : mime->urls()) {
            if (url.isLocalFile()) {
                TelegramClient::instance().sendMediaFile(m_peerId, url.toLocalFile());
            }
        }
        renderTimeline();
        event->acceptProposedAction();
    }
}

} // namespace LightGram
