#include "ControlCenterDialog.hpp"
#include "../core/Localization.hpp"
#include "../core/Settings.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QComboBox>

namespace LightGram {

ControlCenterDialog::ControlCenterDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle("LightGram Control Center");
    setFixedSize(680, 520);
    setupUi();
}

void ControlCenterDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(20, 20, 20, 20);
    mainLayout->setSpacing(16);

    // Header
    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel("⚡ LightGram Control Center", this);
    title->setStyleSheet("font-size: 20px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    // Language dropdown
    QComboBox* langCombo = new QComboBox(this);
    langCombo->addItem("🇺🇸 English", "en");
    langCombo->addItem("🇷🇺 Русский", "ru");
    langCombo->addItem("🇵🇱 Polski", "pl");
    langCombo->setCurrentIndex(Localization::instance().currentLanguage() == Language::Russian ? 1 : (Localization::instance().currentLanguage() == Language::Polish ? 2 : 0));
    connect(langCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), [](int idx) {
        if (idx == 1) {
            Localization::instance().setLanguage(Language::Russian);
            Settings::instance().setLanguage("ru");
        } else if (idx == 2) {
            Localization::instance().setLanguage(Language::Polish);
            Settings::instance().setLanguage("pl");
        } else {
            Localization::instance().setLanguage(Language::English);
            Settings::instance().setLanguage("en");
        }
    });
    topRow->addWidget(langCombo);

    mainLayout->addLayout(topRow);

    // Tiles Grid (3x3)
    QGridLayout* grid = new QGridLayout();
    grid->setSpacing(12);

    // 1. Ghost Mode
    QPushButton* ghostTile = createTile("👻", trL("GhostMode"), "Read suppression & stealth");
    connect(ghostTile, &QPushButton::clicked, [this]() {
        bool current = Settings::instance().isGhostModeEnabled();
        Settings::instance().setGhostModeEnabled(!current);
    });
    grid->addWidget(ghostTile, 0, 0);

    // 2. Spy Archive
    QPushButton* spyTile = createTile("🕵️‍♂️", trL("SpyMode"), "Deleted & edit revisions");
    connect(spyTile, &QPushButton::clicked, [this]() {
        emit openSpyArchiveRequested();
        accept();
    });
    grid->addWidget(spyTile, 0, 1);

    // 3. Statistics Center
    QPushButton* statsTile = createTile("📊", trL("Statistics_Title"), "Activity charts & export");
    connect(statsTile, &QPushButton::clicked, [this]() {
        emit openStatisticsRequested();
        accept();
    });
    grid->addWidget(statsTile, 0, 2);

    // 4. Media Vault
    QPushButton* vaultTile = createTile("🛡️", trL("MediaVault_Title"), "Encrypted files storage");
    connect(vaultTile, &QPushButton::clicked, [this]() {
        emit openMediaVaultRequested();
        accept();
    });
    grid->addWidget(vaultTile, 1, 0);

    // 5. Circle Studio
    QPushButton* circleTile = createTile("⭕", trL("CircleStudio_Title"), "1:1 video notes tool");
    connect(circleTile, &QPushButton::clicked, [this]() {
        emit openCircleStudioRequested();
        accept();
    });
    grid->addWidget(circleTile, 1, 1);

    // 6. LightGram Studio
    QPushButton* studioTile = createTile("🎨", trL("Studio_Title"), "Liquid Glass & colors");
    connect(studioTile, &QPushButton::clicked, [this]() {
        emit openStudioRequested();
        accept();
    });
    grid->addWidget(studioTile, 1, 2);

    // 7. Smart Folders
    QPushButton* foldersTile = createTile("📁", trL("SmartFolders_Title"), "Tabs & chat organization");
    connect(foldersTile, &QPushButton::clicked, [this]() {
        emit openSmartFoldersRequested();
        accept();
    });
    grid->addWidget(foldersTile, 2, 0);

    // 8. Personal Notes
    QPushButton* notesTile = createTile("📝", trL("Notes_Title"), "Reminders & saved items");
    connect(notesTile, &QPushButton::clicked, [this]() {
        emit openNotesRequested();
        accept();
    });
    grid->addWidget(notesTile, 2, 1);

    // 9. Diagnostics & Privacy
    QPushButton* diagTile = createTile("📶", trL("Diagnostics_Title"), "DC1-DC5 latency & sockets");
    connect(diagTile, &QPushButton::clicked, [this]() {
        emit openDiagnosticsRequested();
        accept();
    });
    grid->addWidget(diagTile, 2, 2);

    mainLayout->addLayout(grid);

    // Close button
    QHBoxLayout* botRow = new QHBoxLayout();
    botRow->addStretch();
    QPushButton* closeBtn = new QPushButton(trL("Close"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::accept);
    botRow->addWidget(closeBtn);
    mainLayout->addLayout(botRow);
}

QPushButton* ControlCenterDialog::createTile(const QString& icon, const QString& title, const QString& subtitle) {
    QPushButton* btn = new QPushButton(this);
    btn->setFixedHeight(90);
    btn->setCursor(Qt::PointingHandCursor);

    QVBoxLayout* l = new QVBoxLayout(btn);
    l->setContentsMargins(12, 10, 12, 10);
    l->setSpacing(4);

    QLabel* iconLbl = new QLabel(icon, btn);
    iconLbl->setStyleSheet("font-size: 22px;");
    l->addWidget(iconLbl);

    QLabel* titleLbl = new QLabel(title, btn);
    titleLbl->setStyleSheet("font-size: 13px; font-weight: bold; color: #FFFFFF;");
    l->addWidget(titleLbl);

    QLabel* subLbl = new QLabel(subtitle, btn);
    subLbl->setStyleSheet("font-size: 11px; color: #888888;");
    l->addWidget(subLbl);

    btn->setStyleSheet(
        "QPushButton { background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.08); "
        "border-radius: 14px; text-align: left; } "
        "QPushButton:hover { background: rgba(237, 180, 0, 0.15); border: 1px solid rgba(237, 180, 0, 0.4); }"
    );
    return btn;
}

} // namespace LightGram
