#pragma once

#include <QWidget>
#include <QVBoxLayout>
#include <QLineEdit>
#include <QListWidget>
#include <QPushButton>
#include <QLabel>
#include <cstdint>
#include "../core/Types.hpp"

namespace LightGram {

class SidebarWidget : public QWidget {
    Q_OBJECT
public:
    explicit SidebarWidget(QWidget* parent = nullptr);

    void refreshChats();
    void selectChat(int64_t peerId);
    int64_t selectedPeerId() const { return m_selectedPeerId; }

signals:
    void chatSelected(int64_t peerId, const QString& title);
    void openControlCenterRequested();
    void openStudioRequested();
    void openDiagnosticsRequested();
    void openInNewWindowRequested(int64_t peerId);
    void accountSwitchRequested(int index);

private slots:
    void onSearchTextChanged(const QString& query);
    void onChatItemClicked(QListWidgetItem* item);
    void onCustomContextMenuRequested(const QPoint& pos);
    void onFolderClicked(const QString& folderId);

private:
    void setupUi();
    void renderFolderButtons();

    QVBoxLayout* m_mainLayout = nullptr;
    QLineEdit* m_searchEdit = nullptr;
    QHBoxLayout* m_folderLayout = nullptr;
    QListWidget* m_chatListWidget = nullptr;
    QLabel* m_ghostIndicator = nullptr;

    QString m_activeFolder = "all";
    int64_t m_selectedPeerId = 0;
};

} // namespace LightGram
