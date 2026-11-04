#pragma once

#include <QDialog>
#include <QTabWidget>
#include <QListWidget>
#include <QLineEdit>
#include <QComboBox>
#include <QLabel>
#include <QPushButton>
#include "../core/SpyManager.hpp"

namespace LightGram {

class SpyArchiveDialog : public QDialog {
    Q_OBJECT
public:
    explicit SpyArchiveDialog(QWidget* parent = nullptr);

private slots:
    void reloadData();
    void onSearchChanged(const QString& query);
    void onChatFilterChanged(int index);
    void onClearArchiveClicked();
    void onExportJsonClicked();
    void onDeletedItemDoubleClicked(QListWidgetItem* item);
    void onEditedItemDoubleClicked(QListWidgetItem* item);

private:
    void setupUi();

    QLineEdit* m_searchEdit = nullptr;
    QComboBox* m_chatFilterCombo = nullptr;
    QTabWidget* m_tabWidget = nullptr;
    QListWidget* m_deletedList = nullptr;
    QListWidget* m_editedList = nullptr;
    QLabel* m_sizeLabel = nullptr;
};

} // namespace LightGram
