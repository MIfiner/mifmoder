#pragma once

#include <QDialog>
#include <QListWidget>
#include <QPushButton>

namespace LightGram {

class SmartFoldersDialog : public QDialog {
    Q_OBJECT
public:
    explicit SmartFoldersDialog(QWidget* parent = nullptr);

private slots:
    void onSaveClicked();

private:
    void setupUi();

    QListWidget* m_foldersList = nullptr;
};

} // namespace LightGram
