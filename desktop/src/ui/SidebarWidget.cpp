#include "SidebarWidget.hpp"
#include "../core/TelegramClient.hpp"
#include "../core/ThemeEngine.hpp"
#include "../core/GhostController.hpp"
#include "../core/Settings.hpp"
#include "../core/Localization.hpp"
#include <QHBoxLayout>
#include <QMenu>
#include <QPainter>
#include <QDateTime>

namespace LightGram {

SidebarWidget::SidebarWidget(QWidget* parent) : QWidget(parent) {
    setMinimumWidth(280);
    setMaximumWidth(360);
    setupUi();
    refreshChats();

    connect(&TelegramClient::instance(), &TelegramClient::chatsUpdated, this, &SidebarWidget::refreshChats);
    connect(&Settings::instance(), &Settings::ghostModeChanged, this, [this](bool enabled) {
        if (m_ghostIndicator) {
            m_ghostIndicator->setVisible(enabled);
        }
    });
}

void SidebarWidget::setupUi() {
    m_mainLayout = new QVBoxLayout(this);
    m_mainLayout->setContentsMargins(12, 12, 12, 12);
    m_mainLayout->setSpacing(10);

    // Header Bar
    QHBoxLayout* headerLayout = new QHBoxLayout();
    headerLayout->setContentsMargins(0, 0, 0, 0);

    QLabel* logoLabel = new QLabel(this);
    QPixmap logoPix(":/icons/amber.png");
    if (!logoPix.isNull()) {
        logoLabel->setPixmap(logoPix.scaled(28, 28, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    } else {
        logoLabel->setText("⚡");
    }
    headerLayout->addWidget(logoLabel);

    QLabel* titleLabel = new QLabel("LightGram", this);
    titleLabel->setStyleSheet("font-size: 17px; font-weight: 700; color: #FFFFFF;");
    headerLayout->addWidget(titleLabel);

    m_ghostIndicator = new QLabel("👻 GHOST", this);
    m_ghostIndicator->setStyleSheet(
        "background: rgba(237, 180, 0, 0.2); color: #EDB400; border: 1px solid #EDB400; "
        "border-radius: 9px; padding: 2px 6px; font-size: 10px; font-weight: bold;"
    );
    m_ghostIndicator->setVisible(Settings::instance().isGhostModeEnabled());
    headerLayout->addWidget(m_ghostIndicator);

    headerLayout->addStretch();

    // Studio Quick Button
    QPushButton* studioBtn = new QPushButton("🎨", this);
    studioBtn->setFixedSize(30, 30);
    studioBtn->setToolTip("LightGram Studio");
    studioBtn->setStyleSheet("QPushButton { border-radius: 15px; background: rgba(255, 255, 255, 0.08); font-size: 14px; } QPushButton:hover { background: rgba(255, 255, 255, 0.18); }");
    connect(studioBtn, &QPushButton::clicked, this, &SidebarWidget::openStudioRequested);
    headerLayout->addWidget(studioBtn);

    // Control Center Quick Button
    QPushButton* hubBtn = new QPushButton("⚙️", this);
    hubBtn->setFixedSize(30, 30);
    hubBtn->setToolTip("Control Center");
    hubBtn->setStyleSheet("QPushButton { border-radius: 15px; background: rgba(255, 255, 255, 0.08); font-size: 14px; } QPushButton:hover { background: rgba(255, 255, 255, 0.18); }");
    connect(hubBtn, &QPushButton::clicked, this, &SidebarWidget::openControlCenterRequested);
    headerLayout->addWidget(hubBtn);

    m_mainLayout->addLayout(headerLayout);

    // Global Search LineEdit
    m_searchEdit = new QLineEdit(this);
    m_searchEdit->setPlaceholderText(trL("Desktop_GlobalSearch"));
    m_searchEdit->setStyleSheet(
        "QLineEdit { background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.1); "
        "border-radius: 10px; padding: 7px 12px; color: #FFFFFF; font-size: 12px; }"
        "QLineEdit:focus { border: 1px solid #EDB400; background: rgba(255, 255, 255, 0.1); }"
    );
    connect(m_searchEdit, &QLineEdit::textChanged, this, &SidebarWidget::onSearchTextChanged);
    m_mainLayout->addWidget(m_searchEdit);

    // Smart Folders Navigation
    renderFolderButtons();

    // Chat List
    m_chatListWidget = new QListWidget(this);
    m_chatListWidget->setStyleSheet(
        "QListWidget { background: transparent; border: none; outline: none; }"
        "QListWidget::item { border-radius: 12px; padding: 6px; margin: 2px 0px; }"
        "QListWidget::item:hover { background: rgba(255, 255, 255, 0.06); }"
        "QListWidget::item:selected { background: rgba(237, 180, 0, 0.18); border: 1px solid rgba(237, 180, 0, 0.4); }"
    );
    m_chatListWidget->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(m_chatListWidget, &QListWidget::itemClicked, this, &SidebarWidget::onChatItemClicked);
    connect(m_chatListWidget, &QListWidget::customContextMenuRequested, this, &SidebarWidget::onCustomContextMenuRequested);
    m_mainLayout->addWidget(m_chatListWidget);

    // Account Switcher Footer
    QHBoxLayout* accountLayout = new QHBoxLayout();
    accountLayout->setContentsMargins(4, 4, 4, 4);

    QLabel* avatarIcon = new QLabel("👤", this);
    avatarIcon->setStyleSheet("background: rgba(255, 255, 255, 0.1); border-radius: 14px; padding: 6px; font-size: 14px;");
    accountLayout->addWidget(avatarIcon);

    QVBoxLayout* accInfoLayout = new QVBoxLayout();
    accInfoLayout->setSpacing(0);
    QLabel* accName = new QLabel("Primary Account", this);
    accName->setStyleSheet("font-size: 12px; font-weight: 600; color: #FFFFFF;");
    accInfoLayout->addWidget(accName);

    QLabel* accPhone = new QLabel("+1 800 555-0199", this);
    accPhone->setStyleSheet("font-size: 11px; color: #888888;");
    accInfoLayout->addWidget(accPhone);
    accountLayout->addLayout(accInfoLayout);
    accountLayout->addStretch();

    QPushButton* switchAccBtn = new QPushButton("⇄", this);
    switchAccBtn->setFixedSize(26, 26);
    switchAccBtn->setStyleSheet("QPushButton { border-radius: 13px; background: rgba(255, 255, 255, 0.08); font-size: 14px; } QPushButton:hover { background: rgba(255, 255, 255, 0.18); }");
    connect(switchAccBtn, &QPushButton::clicked, this, [this, switchAccBtn]() {
        QMenu menu(this);
        auto accs = TelegramClient::instance().availableAccounts();
        for (int i = 0; i < accs.size(); ++i) {
            menu.addAction(accs[i], [this, i]() {
                TelegramClient::instance().switchAccount(i);
                emit accountSwitchRequested(i);
            });
        }
        menu.addSeparator();
        menu.addAction("＋ " + trL("Desktop_AddAccount"));
        menu.exec(switchAccBtn->mapToGlobal(QPoint(0, switchAccBtn->height())));
    });
    accountLayout->addWidget(switchAccBtn);

    m_mainLayout->addLayout(accountLayout);
}

void SidebarWidget::renderFolderButtons() {
    QWidget* folderContainer = new QWidget(this);
    m_folderLayout = new QHBoxLayout(folderContainer);
    m_folderLayout->setContentsMargins(0, 0, 0, 0);
    m_folderLayout->setSpacing(4);

    struct FolderSpec { QString id; QString name; QString icon; };
    QVector<FolderSpec> folders = {
        { "all", trL("SmartFolders_All"), "💬" },
        { "unread", trL("SmartFolders_Unread"), "📬" },
        { "personal", trL("SmartFolders_Personal"), "👤" },
        { "groups", trL("SmartFolders_Groups"), "👥" },
        { "channels", trL("SmartFolders_Channels"), "📢" }
    };

    for (const auto& f : folders) {
        QPushButton* btn = new QPushButton(f.icon + " " + f.name, folderContainer);
        btn->setStyleSheet(QString(
            "QPushButton { font-size: 11px; padding: 4px 8px; border-radius: 8px; border: none; "
            "background: %1; color: %2; } QPushButton:hover { background: rgba(255, 255, 255, 0.12); }"
        ).arg(m_activeFolder == f.id ? "rgba(237, 180, 0, 0.25)" : "rgba(255, 255, 255, 0.05)")
         .arg(m_activeFolder == f.id ? "#EDB400" : "#AAAAAA"));

        QString fid = f.id;
        connect(btn, &QPushButton::clicked, [this, fid]() {
            onFolderClicked(fid);
        });
        m_folderLayout->addWidget(btn);
    }
    m_folderLayout->addStretch();
    m_mainLayout->addWidget(folderContainer);
}

void SidebarWidget::onFolderClicked(const QString& folderId) {
    m_activeFolder = folderId;
    refreshChats();
}

void SidebarWidget::onSearchTextChanged(const QString& query) {
    Q_UNUSED(query);
    refreshChats();
}

void SidebarWidget::refreshChats() {
    m_chatListWidget->clear();
    QString query = m_searchEdit ? m_searchEdit->text().trimmed().toLower() : "";
    auto chats = TelegramClient::instance().getChats(m_activeFolder);

    const auto& theme = ThemeEngine::instance().currentTheme();
    QString accent = theme.primaryAccent.name();

    for (const auto& c : chats) {
        if (!query.isEmpty() && !c.title.toLower().contains(query) && !c.lastMessage.toLower().contains(query)) {
            continue;
        }

        QListWidgetItem* item = new QListWidgetItem(m_chatListWidget);
        item->setData(Qt::UserRole, (qlonglong)c.peerId);
        item->setSizeHint(QSize(250, 64));

        QWidget* itemWidget = new QWidget();
        QHBoxLayout* hl = new QHBoxLayout(itemWidget);
        hl->setContentsMargins(8, 6, 8, 6);
        hl->setSpacing(10);

        // Avatar
        QLabel* avatarLbl = new QLabel(itemWidget);
        avatarLbl->setFixedSize(40, 40);
        QString initial = c.title.isEmpty() ? "?" : QString(c.title.at(0).toUpper());
        avatarLbl->setText(initial);
        avatarLbl->setAlignment(Qt::AlignCenter);

        QString avBg = "#252528";
        if (c.type == PeerType::Channel) avBg = "#E67E22";
        else if (c.type == PeerType::Group) avBg = "#2980B9";
        else if (c.type == PeerType::Bot) avBg = "#8E44AD";
        else avBg = "#27AE60";

        avatarLbl->setStyleSheet(QString(
            "background-color: %1; color: #FFFFFF; font-size: 16px; font-weight: bold; border-radius: 20px;"
        ).arg(avBg));
        hl->addWidget(avatarLbl);

        // Content
        QVBoxLayout* vl = new QVBoxLayout();
        vl->setContentsMargins(0, 0, 0, 0);
        vl->setSpacing(2);

        QHBoxLayout* topRow = new QHBoxLayout();
        topRow->setContentsMargins(0, 0, 0, 0);

        QLabel* titleLbl = new QLabel(c.title, itemWidget);
        titleLbl->setStyleSheet("font-size: 13px; font-weight: 600; color: #FFFFFF;");
        topRow->addWidget(titleLbl);
        topRow->addStretch();

        QDateTime dt = QDateTime::fromSecsSinceEpoch(c.lastMessageTime);
        QLabel* timeLbl = new QLabel(dt.toString("HH:mm"), itemWidget);
        timeLbl->setStyleSheet("font-size: 11px; color: #888888;");
        topRow->addWidget(timeLbl);
        vl->addLayout(topRow);

        QHBoxLayout* botRow = new QHBoxLayout();
        botRow->setContentsMargins(0, 0, 0, 0);

        QLabel* msgLbl = new QLabel(c.lastMessage, itemWidget);
        msgLbl->setStyleSheet("font-size: 12px; color: #AAAAAA;");
        msgLbl->setMaximumWidth(180);
        botRow->addWidget(msgLbl);
        botRow->addStretch();

        if (c.unreadCount > 0) {
            QLabel* unreadLbl = new QLabel(QString::number(c.unreadCount), itemWidget);
            unreadLbl->setStyleSheet(QString(
                "background-color: %1; color: #000000; font-size: 11px; font-weight: bold; "
                "border-radius: 10px; padding: 2px 7px;"
            ).arg(accent));
            botRow->addWidget(unreadLbl);
        }
        vl->addLayout(botRow);

        hl->addLayout(vl);
        m_chatListWidget->setItemWidget(item, itemWidget);

        if (c.peerId == m_selectedPeerId) {
            item->setSelected(true);
        }
    }
}

void SidebarWidget::selectChat(int64_t peerId) {
    m_selectedPeerId = peerId;
    for (int i = 0; i < m_chatListWidget->count(); ++i) {
        QListWidgetItem* it = m_chatListWidget->item(i);
        if (it->data(Qt::UserRole).toLongLong() == peerId) {
            it->setSelected(true);
            m_chatListWidget->scrollToItem(it);
            break;
        }
    }
}

void SidebarWidget::onChatItemClicked(QListWidgetItem* item) {
    if (!item) return;
    int64_t peerId = item->data(Qt::UserRole).toLongLong();
    m_selectedPeerId = peerId;
    ChatSummary chat = TelegramClient::instance().getChat(peerId);
    emit chatSelected(peerId, chat.title);
}

void SidebarWidget::onCustomContextMenuRequested(const QPoint& pos) {
    QListWidgetItem* item = m_chatListWidget->itemAt(pos);
    if (!item) return;

    int64_t peerId = item->data(Qt::UserRole).toLongLong();
    ChatSummary chat = TelegramClient::instance().getChat(peerId);

    QMenu menu(this);
    menu.addAction("📂 " + trL("Desktop_Tabs"), [this, peerId, chat]() {
        emit chatSelected(peerId, chat.title);
    });

    menu.addAction("🗗 " + trL("Desktop_DetachWindow"), [this, peerId]() {
        emit openInNewWindowRequested(peerId);
    });

    menu.addSeparator();

    // Ghost Mode manual mark as read
    menu.addAction("✓ Mark as Read", [peerId]() {
        GhostController::instance().markPeerAsReadManually(peerId);
        TelegramClient::instance().markAsRead(peerId);
    });

    menu.addAction("🔕 Mute Notifications");
    menu.addAction("🗑 Clear Chat History");

    menu.exec(m_chatListWidget->mapToGlobal(pos));
}

} // namespace LightGram
