#include "SmartFoldersDialog.hpp"
#include "../core/Localization.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QCheckBox>
#include <QMessageBox>

namespace LightGram {

SmartFoldersDialog::SmartFoldersDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("SmartFolders_Title"));
    setFixedSize(420, 480);
    setupUi();
}

void SmartFoldersDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(18, 18, 18, 18);
    mainLayout->setSpacing(12);

    QLabel* title = new QLabel("📁 " + trL("SmartFolders_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    mainLayout->addWidget(title);

    QLabel* sub = new QLabel("Configure which tabs appear in the top folders bar:", this);
    sub->setStyleSheet("font-size: 12px; color: #888888;");
    mainLayout->addWidget(sub);

    m_foldersList = new QListWidget(this);
    m_foldersList->setStyleSheet(
        "QListWidget { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; } "
        "QListWidget::item { padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.04); }"
    );

    struct FolderItem { QString icon; QString name; bool defOn; };
    QVector<FolderItem> items = {
        { "💬", trL("SmartFolders_All"), true },
        { "📬", trL("SmartFolders_Unread"), true },
        { "👤", trL("SmartFolders_Personal"), true },
        { "👥", trL("SmartFolders_Groups"), true },
        { "📢", trL("SmartFolders_Channels"), true },
        { "🤖", trL("SmartFolders_Bots"), true },
        { "💼", trL("SmartFolders_Work"), false },
        { "⭐", trL("SmartFolders_Important"), false },
        { "📦", trL("SmartFolders_Archived"), true }
    };

    for (const auto& it : items) {
        QListWidgetItem* item = new QListWidgetItem(m_foldersList);
        item->setText(it.icon + "  " + it.name);
        item->setFlags(item->flags() | Qt::ItemIsUserCheckable);
        item->setCheckState(it.defOn ? Qt::Checked : Qt::Unchecked);
    }
    mainLayout->addWidget(m_foldersList, 1);

    QHBoxLayout* botRow = new QHBoxLayout();
    botRow->addStretch();

    QPushButton* saveBtn = new QPushButton(trL("Save"), this);
    saveBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(saveBtn, &QPushButton::clicked, this, &SmartFoldersDialog::onSaveClicked);
    botRow->addWidget(saveBtn);

    QPushButton* closeBtn = new QPushButton(trL("Close"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::reject);
    botRow->addWidget(closeBtn);

    mainLayout->addLayout(botRow);
}

void SmartFoldersDialog::onSaveClicked() {
    QMessageBox::information(this, "Smart Folders", "Smart folders configuration updated!");
    accept();
}

} // namespace LightGram
