#pragma once

#include <QMainWindow>
#include <QSplitter>
#include <QSystemTrayIcon>
#include "SidebarWidget.hpp"
#include "ChatTabsWidget.hpp"
#include "ChatViewWidget.hpp"
#include "../core/Types.hpp"

namespace LightGram {

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget* parent = nullptr);
    ~MainWindow() override;

public slots:
    void openChatInTab(int64_t peerId, const QString& title);
    void openChatInNewWindow(int64_t peerId);
    void openStudio();
    void openSpyArchive();
    void openStatistics();
    void openMediaVault();
    void openCircleStudio();
    void openSmartFolders();
    void openNotes();
    void openControlCenter();
    void openDiagnostics();

protected:
    void closeEvent(QCloseEvent* event) override;
    void keyPressEvent(QKeyEvent* event) override;

private slots:
    void onTabSelected(int64_t peerId);
    void onTabClosed(int64_t peerId);
    void onTrayIconActivated(QSystemTrayIcon::ActivationReason reason);

private:
    void setupUi();
    void setupTray();
    void setupShortcuts();

    QSplitter* m_splitter = nullptr;
    SidebarWidget* m_sidebar = nullptr;
    QWidget* m_rightContainer = nullptr;
    ChatTabsWidget* m_tabsWidget = nullptr;
    ChatViewWidget* m_chatView = nullptr;
    QSystemTrayIcon* m_trayIcon = nullptr;

    QVector<QMainWindow*> m_detachedWindows;
};

} // namespace LightGram
