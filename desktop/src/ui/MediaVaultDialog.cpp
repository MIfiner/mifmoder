#include "MediaVaultDialog.hpp"
#include "../core/Localization.hpp"
#include "../core/ThemeEngine.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QMessageBox>
#include <QDesktopServices>
#include <QUrl>
#include <QDateTime>

namespace LightGram {

MediaVaultDialog::MediaVaultDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("MediaVault_Title"));
    setMinimumSize(800, 540);
    setupUi();
    reloadItems();

    connect(&MediaVaultManager::instance(), &MediaVaultManager::vaultUpdated, this, &MediaVaultDialog::reloadItems);
}

void MediaVaultDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(16, 16, 16, 16);
    mainLayout->setSpacing(12);

    // Top Row
    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel("🛡 " + trL("MediaVault_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    m_storageLabel = new QLabel("Used: 0 B", this);
    m_storageLabel->setStyleSheet("font-size: 12px; color: #EDB400; font-weight: 600;");
    topRow->addWidget(m_storageLabel);

    QPushButton* exportBatchBtn = new QPushButton("📦 " + trL("MediaVault_ExportBatch"), this);
    connect(exportBatchBtn, &QPushButton::clicked, this, &MediaVaultDialog::onExportBatchClicked);
    topRow->addWidget(exportBatchBtn);

    QPushButton* clearBtn = new QPushButton("🗑 " + trL("Clear"), this);
    clearBtn->setStyleSheet("QPushButton { color: #FF3B30; }");
    connect(clearBtn, &QPushButton::clicked, this, &MediaVaultDialog::onClearVaultClicked);
    topRow->addWidget(clearBtn);

    mainLayout->addLayout(topRow);

    // Filter strip & Search
    QHBoxLayout* navRow = new QHBoxLayout();
    m_filterLayout = new QHBoxLayout();
    m_filterLayout->setSpacing(4);

    struct Opt { QString key; QString label; QString icon; };
    QVector<Opt> filters = {
        { "all", trL("MediaVault_All"), "📁" },
        { "photo", trL("MediaVault_Photos"), "🖼" },
        { "video", trL("MediaVault_Videos"), "🎥" },
        { "circle", trL("MediaVault_Circles"), "⭕" },
        { "voice", trL("MediaVault_Voice"), "🎙" },
        { "file", trL("MediaVault_Files"), "📄" },
        { "favorites", trL("MediaVault_Favorites"), "⭐" }
    };

    for (const auto& f : filters) {
        QPushButton* btn = new QPushButton(f.icon + " " + f.label, this);
        btn->setStyleSheet(QString(
            "QPushButton { font-size: 11px; padding: 4px 10px; border-radius: 8px; border: none; "
            "background: %1; color: %2; } QPushButton:hover { background: rgba(255,255,255,0.12); }"
        ).arg(m_activeFilter == f.key ? "#EDB400" : "rgba(255,255,255,0.06)")
         .arg(m_activeFilter == f.key ? "#000000" : "#FFFFFF"));

        QString key = f.key;
        connect(btn, &QPushButton::clicked, [this, key]() {
            onFilterClicked(key);
        });
        m_filterLayout->addWidget(btn);
    }
    navRow->addLayout(m_filterLayout);
    navRow->addStretch();

    m_searchEdit = new QLineEdit(this);
    m_searchEdit->setPlaceholderText("Search files...");
    m_searchEdit->setFixedWidth(200);
    connect(m_searchEdit, &QLineEdit::textChanged, this, &MediaVaultDialog::onSearchChanged);
    navRow->addWidget(m_searchEdit);

    mainLayout->addLayout(navRow);

    // List of Items
    m_itemsList = new QListWidget(this);
    m_itemsList->setStyleSheet(
        "QListWidget { background: transparent; border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; } "
        "QListWidget::item { padding: 10px; border-bottom: 1px solid rgba(255,255,255,0.05); } "
        "QListWidget::item:hover { background: rgba(255,255,255,0.04); }"
    );
    connect(m_itemsList, &QListWidget::itemDoubleClicked, this, &MediaVaultDialog::onItemDoubleClicked);
    mainLayout->addWidget(m_itemsList, 1);
}

void MediaVaultDialog::onFilterClicked(const QString& filter) {
    m_activeFilter = filter;
    reloadItems();
}

void MediaVaultDialog::onSearchChanged(const QString& query) {
    Q_UNUSED(query);
    reloadItems();
}

void MediaVaultDialog::reloadItems() {
    m_storageLabel->setText("Storage: " + MediaVaultManager::instance().formattedStorageSize());

    m_itemsList->clear();
    QString query = m_searchEdit ? m_searchEdit->text() : "";
    auto items = MediaVaultManager::instance().fetchAllItems(m_activeFilter, query);

    for (const auto& it : items) {
        QString dateStr = QDateTime::fromSecsSinceEpoch(it.savedTimestamp).toString("dd.MM.yyyy HH:mm");
        double kb = (double)it.fileSize / 1024.0;
        QString sizeStr = (kb < 1024) ? QString("%1 KB").arg(QString::number(kb, 'f', 1)) : QString("%1 MB").arg(QString::number(kb / 1024.0, 'f', 1));

        QString star = it.isFavorite ? "⭐ " : "";
        QString icon = "📄";
        if (it.mediaType == "photo") icon = "🖼";
        else if (it.mediaType == "video") icon = "🎥";
        else if (it.mediaType == "circle") icon = "⭕";
        else if (it.mediaType == "voice") icon = "🎙";

        QString label = QString("%1%2  %3 (%4) • From %5 in %6 • Saved: %7")
                            .arg(star)
                            .arg(icon)
                            .arg(it.fileName)
                            .arg(sizeStr)
                            .arg(it.senderName)
                            .arg(it.chatTitle)
                            .arg(dateStr);

        QListWidgetItem* listItem = new QListWidgetItem(label, m_itemsList);
        listItem->setData(Qt::UserRole, it.id);
    }

    if (m_itemsList->count() == 0) {
        new QListWidgetItem(trL("MediaVault_Empty"), m_itemsList);
    }
}

void MediaVaultDialog::onItemDoubleClicked(QListWidgetItem* listItem) {
    if (!listItem) return;
    QString id = listItem->data(Qt::UserRole).toString();
    if (id.isEmpty()) return;

    MediaVaultItem it = MediaVaultManager::instance().getItem(id);
    if (it.id.isEmpty()) return;

    QMessageBox box(this);
    box.setWindowTitle(it.fileName);
    box.setText(QString("File: %1\nType: %2\nSize: %3 bytes\nOrigin: %4 (%5)")
                    .arg(it.fileName)
                    .arg(it.mediaType)
                    .arg(it.fileSize)
                    .arg(it.senderName)
                    .arg(it.chatTitle));

    QPushButton* openBtn = box.addButton("Open File", QMessageBox::ActionRole);
    QPushButton* favBtn = box.addButton(it.isFavorite ? "Unfavorite" : "Favorite ★", QMessageBox::ActionRole);
    QPushButton* expBtn = box.addButton("Export File", QMessageBox::ActionRole);
    QPushButton* delBtn = box.addButton("Delete", QMessageBox::DestructiveRole);
    box.addButton(QMessageBox::Close);
    box.exec();

    if (box.clickedButton() == openBtn) {
        QString absPath = MediaVaultManager::instance().resolveItemAbsolutePath(it);
        QDesktopServices::openUrl(QUrl::fromLocalFile(absPath));
    } else if (box.clickedButton() == favBtn) {
        MediaVaultManager::instance().toggleFavorite(it.id);
        reloadItems();
    } else if (box.clickedButton() == expBtn) {
        QString dest = QFileDialog::getSaveFileName(this, "Export File", QDir::homePath() + "/" + it.fileName);
        if (!dest.isEmpty()) {
            MediaVaultManager::instance().exportItem(it.id, dest);
            QMessageBox::information(this, "Export", "File exported successfully!");
        }
    } else if (box.clickedButton() == delBtn) {
        MediaVaultManager::instance().deleteItem(it.id);
        reloadItems();
    }
}

void MediaVaultDialog::onExportBatchClicked() {
    QString dir = QFileDialog::getExistingDirectory(this, "Select Export Directory", QDir::homePath());
    if (!dir.isEmpty()) {
        int count = MediaVaultManager::instance().batchExport(dir);
        QMessageBox::information(this, "Batch Export", QString("Exported %1 files to %2").arg(count).arg(dir));
    }
}

void MediaVaultDialog::onClearVaultClicked() {
    if (QMessageBox::question(this, "Clear Vault", trL("MediaVault_ClearConfirm")) == QMessageBox::Yes) {
        MediaVaultManager::instance().clearVault(true);
        reloadItems();
    }
}

} // namespace LightGram
