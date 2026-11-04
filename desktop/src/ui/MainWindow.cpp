#include "MainWindow.hpp"
#include "LightGramStudioDialog.hpp"
#include "SpyArchiveDialog.hpp"
#include "StatisticsDialog.hpp"
#include "MediaVaultDialog.hpp"
#include "CircleStudioDialog.hpp"
#include "SmartFoldersDialog.hpp"
#include "NotesDialog.hpp"
#include "ControlCenterDialog.hpp"
#include "DiagnosticsDialog.hpp"
#include "../core/TelegramClient.hpp"
#include "../core/ThemeEngine.hpp"
#include "../core/Settings.hpp"
#include "../core/Localization.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QCloseEvent>
#include <QKeyEvent>
#include <QMenu>
#include <QShortcut>
#include <QApplication>

namespace LightGram {

MainWindow::MainWindow(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle("LightGram Desktop");
    setMinimumSize(960, 640);
    resize(1140, 740);

    setupUi();
    setupTray();
    setupShortcuts();

    // Default open first chat
    auto chats = TelegramClient::instance().getChats("all");
    if (!chats.isEmpty()) {
        openChatInTab(chats.first().peerId, chats.first().title);
    }
}

MainWindow::~MainWindow() {
    for (auto win : m_detachedWindows) {
        if (win) win->deleteLater();
    }
}

void MainWindow::setupUi() {
    QWidget* centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    QHBoxLayout* rootLayout = new QHBoxLayout(centralWidget);
    rootLayout->setContentsMargins(0, 0, 0, 0);
    rootLayout->setSpacing(0);

    m_splitter = new QSplitter(Qt::Horizontal, centralWidget);
    m_splitter->setHandleWidth(1);
    m_splitter->setStyleSheet("QSplitter::handle { background: rgba(255, 255, 255, 0.08); }");

    // Left: Sidebar
    m_sidebar = new SidebarWidget(m_splitter);
    connect(m_sidebar, &SidebarWidget::chatSelected, this, &MainWindow::openChatInTab);
    connect(m_sidebar, &SidebarWidget::openStudioRequested, this, &MainWindow::openStudio);
    connect(m_sidebar, &SidebarWidget::openControlCenterRequested, this, &MainWindow::openControlCenter);
    connect(m_sidebar, &SidebarWidget::openDiagnosticsRequested, this, &MainWindow::openDiagnostics);
    connect(m_sidebar, &SidebarWidget::openInNewWindowRequested, this, &MainWindow::openChatInNewWindow);
    m_splitter->addWidget(m_sidebar);

    // Right: Tabs + Chat View
    m_rightContainer = new QWidget(m_splitter);
    QVBoxLayout* rightLayout = new QVBoxLayout(m_rightContainer);
    rightLayout->setContentsMargins(0, 0, 0, 0);
    rightLayout->setSpacing(0);

    m_tabsWidget = new ChatTabsWidget(m_rightContainer);
    connect(m_tabsWidget, &ChatTabsWidget::tabSelected, this, &MainWindow::onTabSelected);
    connect(m_tabsWidget, &ChatTabsWidget::tabClosed, this, &MainWindow::onTabClosed);
    rightLayout->addWidget(m_tabsWidget);

    m_chatView = new ChatViewWidget(m_rightContainer);
    connect(m_chatView, &ChatViewWidget::detachWindowRequested, this, &MainWindow::openChatInNewWindow);
    connect(m_chatView, &ChatViewWidget::openMediaVaultRequested, this, &MainWindow::openMediaVault);
    connect(m_chatView, &ChatViewWidget::openCircleStudioRequested, this, &MainWindow::openCircleStudio);
    rightLayout->addWidget(m_chatView, 1);

    m_splitter->addWidget(m_rightContainer);
    m_splitter->setStretchFactor(0, 0);
    m_splitter->setStretchFactor(1, 1);

    rootLayout->addWidget(m_splitter);
}

void MainWindow::setupTray() {
    m_trayIcon = new QSystemTrayIcon(this);
    QIcon icon(":/icons/amber.png");
    m_trayIcon->setIcon(icon);
    m_trayIcon->setToolTip("LightGram Desktop");

    QMenu* trayMenu = new QMenu(this);
    trayMenu->addAction("Open LightGram", this, &QMainWindow::showNormal);
    trayMenu->addAction("Control Center", this, &MainWindow::openControlCenter);
    trayMenu->addAction("LightGram Studio", this, &MainWindow::openStudio);
    trayMenu->addAction("Spy Archive", this, &MainWindow::openSpyArchive);
    trayMenu->addSeparator();
    QAction* quitAct = trayMenu->addAction("Quit");
    connect(quitAct, &QAction::triggered, qApp, &QCoreApplication::quit);

    m_trayIcon->setContextMenu(trayMenu);
    connect(m_trayIcon, &QSystemTrayIcon::activated, this, &MainWindow::onTrayIconActivated);
    m_trayIcon->show();
}

void MainWindow::setupShortcuts() {
    // Ctrl+Shift+G: Toggle Ghost Mode
    new QShortcut(QKeySequence("Ctrl+Shift+G"), this, []() {
        bool curr = Settings::instance().isGhostModeEnabled();
        Settings::instance().setGhostModeEnabled(!curr);
    });

    // Ctrl+Shift+S: Open Studio
    new QShortcut(QKeySequence("Ctrl+Shift+S"), this, [this]() {
        openStudio();
    });

    // Ctrl+Shift+A: Open Spy Archive
    new QShortcut(QKeySequence("Ctrl+Shift+A"), this, [this]() {
        openSpyArchive();
    });

    // F11: Fullscreen
    new QShortcut(QKeySequence(Qt::Key_F11), this, [this]() {
        if (isFullScreen()) showNormal();
        else showFullScreen();
    });
}

void MainWindow::openChatInTab(int64_t peerId, const QString& title) {
    m_tabsWidget->addOrSelectTab(peerId, title);
    m_chatView->loadChat(peerId, title);
    m_sidebar->selectChat(peerId);
}

void MainWindow::onTabSelected(int64_t peerId) {
    if (peerId == 0) return;
    ChatSummary chat = TelegramClient::instance().getChat(peerId);
    m_chatView->loadChat(peerId, chat.title);
    m_sidebar->selectChat(peerId);
}

void MainWindow::onTabClosed(int64_t peerId) {
    Q_UNUSED(peerId);
}

void MainWindow::openChatInNewWindow(int64_t peerId) {
    ChatSummary chat = TelegramClient::instance().getChat(peerId);

    QMainWindow* detWin = new QMainWindow();
    detWin->setWindowTitle(chat.title + " — LightGram");
    detWin->resize(700, 600);

    ChatViewWidget* cv = new ChatViewWidget(detWin);
    cv->loadChat(peerId, chat.title);
    detWin->setCentralWidget(cv);

    detWin->show();
    m_detachedWindows.append(detWin);
}

void MainWindow::openStudio() {
    LightGramStudioDialog dlg(this);
    dlg.exec();
}

void MainWindow::openSpyArchive() {
    SpyArchiveDialog dlg(this);
    dlg.exec();
}

void MainWindow::openStatistics() {
    StatisticsDialog dlg(this);
    dlg.exec();
}

void MainWindow::openMediaVault() {
    MediaVaultDialog dlg(this);
    dlg.exec();
}

void MainWindow::openCircleStudio() {
    CircleStudioDialog dlg(this);
    dlg.exec();
}

void MainWindow::openSmartFolders() {
    SmartFoldersDialog dlg(this);
    dlg.exec();
}

void MainWindow::openNotes() {
    NotesDialog dlg(this);
    dlg.exec();
}

void MainWindow::openControlCenter() {
    ControlCenterDialog dlg(this);
    connect(&dlg, &ControlCenterDialog::openStudioRequested, this, &MainWindow::openStudio);
    connect(&dlg, &ControlCenterDialog::openSpyArchiveRequested, this, &MainWindow::openSpyArchive);
    connect(&dlg, &ControlCenterDialog::openStatisticsRequested, this, &MainWindow::openStatistics);
    connect(&dlg, &ControlCenterDialog::openMediaVaultRequested, this, &MainWindow::openMediaVault);
    connect(&dlg, &ControlCenterDialog::openCircleStudioRequested, this, &MainWindow::openCircleStudio);
    connect(&dlg, &ControlCenterDialog::openSmartFoldersRequested, this, &MainWindow::openSmartFolders);
    connect(&dlg, &ControlCenterDialog::openNotesRequested, this, &MainWindow::openNotes);
    connect(&dlg, &ControlCenterDialog::openDiagnosticsRequested, this, &MainWindow::openDiagnostics);
    dlg.exec();
}

void MainWindow::openDiagnostics() {
    DiagnosticsDialog dlg(this);
    dlg.exec();
}

void MainWindow::closeEvent(QCloseEvent* event) {
    if (Settings::instance().minimizeToTray() && m_trayIcon && m_trayIcon->isVisible()) {
        hide();
        event->ignore();
    } else {
        event->accept();
    }
}

void MainWindow::keyPressEvent(QKeyEvent* event) {
    if (event->modifiers() & Qt::ControlModifier) {
        int key = event->key();
        if (key >= Qt::Key_1 && key <= Qt::Key_9) {
            // Switch tabs
            event->accept();
            return;
        }
    }
    QMainWindow::keyPressEvent(event);
}

void MainWindow::onTrayIconActivated(QSystemTrayIcon::ActivationReason reason) {
    if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
        if (isVisible()) {
            if (isMinimized()) showNormal();
            else hide();
        } else {
            showNormal();
            activateWindow();
        }
    }
}

} // namespace LightGram
