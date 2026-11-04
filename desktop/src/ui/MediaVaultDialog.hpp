#pragma once

#include <QDialog>
#include <QListWidget>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QHBoxLayout>
#include "../core/MediaVaultManager.hpp"

namespace LightGram {

class MediaVaultDialog : public QDialog {
    Q_OBJECT
public:
    explicit MediaVaultDialog(QWidget* parent = nullptr);

private slots:
    void reloadItems();
    void onFilterClicked(const QString& filter);
    void onSearchChanged(const QString& query);
    void onExportBatchClicked();
    void onClearVaultClicked();
    void onItemDoubleClicked(QListWidgetItem* item);

private:
    void setupUi();

    QString m_activeFilter = "all";
    QLineEdit* m_searchEdit = nullptr;
    QHBoxLayout* m_filterLayout = nullptr;
    QListWidget* m_itemsList = nullptr;
    QLabel* m_storageLabel = nullptr;
};

} // namespace LightGram
