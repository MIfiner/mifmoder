#include "SpyArchiveDialog.hpp"
#include "../core/Localization.hpp"
#include "../core/ThemeEngine.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMessageBox>
#include <QFileDialog>
#include <QApplication>
#include <QClipboard>
#include <QDateTime>

namespace LightGram {

SpyArchiveDialog::SpyArchiveDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("SpyArchive_Title"));
    setMinimumSize(780, 520);
    setupUi();
    reloadData();

    connect(&SpyManager::instance(), &SpyManager::archiveUpdated, this, &SpyArchiveDialog::reloadData);
}

void SpyArchiveDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(16, 16, 16, 16);
    mainLayout->setSpacing(12);

    // Top Row: Header & Stats
    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel(trL("SpyArchive_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    m_sizeLabel = new QLabel("Archive Size: 0 B", this);
    m_sizeLabel->setStyleSheet("font-size: 12px; color: #AAAAAA;");
    topRow->addWidget(m_sizeLabel);

    QPushButton* exportBtn = new QPushButton("⬇ Export JSON", this);
    connect(exportBtn, &QPushButton::clicked, this, &SpyArchiveDialog::onExportJsonClicked);
    topRow->addWidget(exportBtn);

    QPushButton* clearBtn = new QPushButton("🗑 " + trL("Clear"), this);
    clearBtn->setStyleSheet("QPushButton { color: #FF3B30; }");
    connect(clearBtn, &QPushButton::clicked, this, &SpyArchiveDialog::onClearArchiveClicked);
    topRow->addWidget(clearBtn);

    mainLayout->addLayout(topRow);

    // Search and Filter Bar
    QHBoxLayout* searchRow = new QHBoxLayout();
    m_searchEdit = new QLineEdit(this);
    m_searchEdit->setPlaceholderText("Search deleted messages & edits by text or author...");
    connect(m_searchEdit, &QLineEdit::textChanged, this, &SpyArchiveDialog::onSearchChanged);
    searchRow->addWidget(m_searchEdit, 2);

    m_chatFilterCombo = new QComboBox(this);
    m_chatFilterCombo->addItem("All Chats", 0);
    connect(m_chatFilterCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &SpyArchiveDialog::onChatFilterChanged);
    searchRow->addWidget(m_chatFilterCombo, 1);
    mainLayout->addLayout(searchRow);

    // Tab Widget
    m_tabWidget = new QTabWidget(this);

    // Deleted tab
    m_deletedList = new QListWidget(m_tabWidget);
    m_deletedList->setStyleSheet("QListWidget { background: transparent; border: none; } QListWidget::item { padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.06); }");
    connect(m_deletedList, &QListWidget::itemDoubleClicked, this, &SpyArchiveDialog::onDeletedItemDoubleClicked);
    m_tabWidget->addTab(m_deletedList, "🔴 " + trL("SpyArchive_DeletedTab"));

    // Edited tab
    m_editedList = new QListWidget(m_tabWidget);
    m_editedList->setStyleSheet("QListWidget { background: transparent; border: none; } QListWidget::item { padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.06); }");
    connect(m_editedList, &QListWidget::itemDoubleClicked, this, &SpyArchiveDialog::onEditedItemDoubleClicked);
    m_tabWidget->addTab(m_editedList, "🟡 " + trL("SpyArchive_EditsTab"));

    mainLayout->addWidget(m_tabWidget, 1);
}

void SpyArchiveDialog::reloadData() {
    m_sizeLabel->setText("Archive Size: " + SpyManager::instance().formattedArchiveSize());

    int64_t currentPeerFilter = m_chatFilterCombo->currentData().toLongLong();
    QString query = m_searchEdit->text().trimmed().toLower();

    // Populate Deleted
    m_deletedList->clear();
    auto deleted = SpyManager::instance().fetchAllDeletedMessages(currentPeerFilter);
    for (const auto& r : deleted) {
        if (!query.isEmpty() && !r.text.toLower().contains(query) && !r.authorName.toLower().contains(query) && !r.chatTitle.toLower().contains(query)) {
            continue;
        }

        QString dateStr = QDateTime::fromSecsSinceEpoch(r.deletionTimestamp).toString("dd.MM.yyyy HH:mm");
        QString label = QString("🔴 [%1] %2 (%3):\n\"%4\"")
                            .arg(dateStr)
                            .arg(r.authorName)
                            .arg(r.chatTitle)
                            .arg(r.text.left(100));

        QListWidgetItem* item = new QListWidgetItem(label, m_deletedList);
        item->setData(Qt::UserRole, r.id);
    }
    if (m_deletedList->count() == 0) {
        new QListWidgetItem(trL("SpyArchive_EmptyDeleted"), m_deletedList);
    }

    // Populate Edited
    m_editedList->clear();
    auto edited = SpyManager::instance().fetchAllEditRecords(currentPeerFilter);
    for (const auto& r : edited) {
        if (!query.isEmpty() && !r.previousText.toLower().contains(query) && !r.newText.toLower().contains(query) && !r.authorName.toLower().contains(query)) {
            continue;
        }

        QString dateStr = QDateTime::fromSecsSinceEpoch(r.timestamp).toString("dd.MM.yyyy HH:mm");
        QString label = QString("🟡 [%1] %2 (Rev %3):\nWas: \"%4\"\nNow: \"%5\"")
                            .arg(dateStr)
                            .arg(r.authorName)
                            .arg(r.revision)
                            .arg(r.previousText.left(80))
                            .arg(r.newText.left(80));

        QListWidgetItem* item = new QListWidgetItem(label, m_editedList);
        item->setData(Qt::UserRole, r.id);
    }
    if (m_editedList->count() == 0) {
        new QListWidgetItem(trL("SpyArchive_EmptyEdits"), m_editedList);
    }
}

void SpyArchiveDialog::onSearchChanged(const QString& query) {
    Q_UNUSED(query);
    reloadData();
}

void SpyArchiveDialog::onChatFilterChanged(int index) {
    Q_UNUSED(index);
    reloadData();
}

void SpyArchiveDialog::onClearArchiveClicked() {
    if (QMessageBox::question(this, "Clear Archive", "Are you sure you want to completely erase all preserved deleted messages and edits?") == QMessageBox::Yes) {
        SpyManager::instance().clearAllData();
        reloadData();
    }
}

void SpyArchiveDialog::onExportJsonClicked() {
    QString path = QFileDialog::getSaveFileName(this, "Export Archive JSON", QDir::homePath() + "/lightgram_archive.json", "JSON (*.json)");
    if (!path.isEmpty()) {
        QFile file(path);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(SpyManager::instance().exportArchiveJson());
            QMessageBox::information(this, "Export", "Archive successfully exported to JSON!");
        }
    }
}

void SpyArchiveDialog::onDeletedItemDoubleClicked(QListWidgetItem* item) {
    if (!item) return;
    QString id = item->data(Qt::UserRole).toString();
    if (id.isEmpty()) return;

    for (const auto& r : SpyManager::instance().fetchAllDeletedMessages()) {
        if (r.id == id) {
            QString info = QString("Chat: %1\nAuthor: %2\nSent: %3\nDeleted: %4\n\nFull Message Text:\n%5")
                               .arg(r.chatTitle)
                               .arg(r.authorName)
                               .arg(QDateTime::fromSecsSinceEpoch(r.originalTimestamp).toString())
                               .arg(QDateTime::fromSecsSinceEpoch(r.deletionTimestamp).toString())
                               .arg(r.text);

            QMessageBox box(this);
            box.setWindowTitle("Deleted Message Details");
            box.setText(info);
            QPushButton* copyBtn = box.addButton("Copy Text", QMessageBox::ActionRole);
            QPushButton* delBtn = box.addButton("Delete from Archive", QMessageBox::DestructiveRole);
            box.addButton(QMessageBox::Close);
            box.exec();

            if (box.clickedButton() == copyBtn) {
                QApplication::clipboard()->setText(r.text);
            } else if (box.clickedButton() == delBtn) {
                SpyManager::instance().deleteRecord(r.id, true);
                reloadData();
            }
            break;
        }
    }
}

void SpyArchiveDialog::onEditedItemDoubleClicked(QListWidgetItem* item) {
    if (!item) return;
    QString id = item->data(Qt::UserRole).toString();
    if (id.isEmpty()) return;

    for (const auto& r : SpyManager::instance().fetchAllEditRecords()) {
        if (r.id == id) {
            QString info = QString("Chat: %1\nAuthor: %2\nRevision: %3\nEdited: %4\n\nPrevious Text:\n%5\n\nNew Text:\n%6")
                               .arg(r.chatTitle)
                               .arg(r.authorName)
                               .arg(r.revision)
                               .arg(QDateTime::fromSecsSinceEpoch(r.timestamp).toString())
                               .arg(r.previousText)
                               .arg(r.newText);

            QMessageBox box(this);
            box.setWindowTitle("Edited Message Details");
            box.setText(info);
            QPushButton* copyPrevBtn = box.addButton("Copy Previous", QMessageBox::ActionRole);
            QPushButton* copyNewBtn = box.addButton("Copy New", QMessageBox::ActionRole);
            QPushButton* delBtn = box.addButton("Delete from Archive", QMessageBox::DestructiveRole);
            box.addButton(QMessageBox::Close);
            box.exec();

            if (box.clickedButton() == copyPrevBtn) {
                QApplication::clipboard()->setText(r.previousText);
            } else if (box.clickedButton() == copyNewBtn) {
                QApplication::clipboard()->setText(r.newText);
            } else if (box.clickedButton() == delBtn) {
                SpyManager::instance().deleteRecord(r.id, false);
                reloadData();
            }
            break;
        }
    }
}

} // namespace LightGram
