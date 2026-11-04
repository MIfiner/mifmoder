#include "LightGramStudioDialog.hpp"
#include "../core/Localization.hpp"
#include <QHBoxLayout>
#include <QGridLayout>
#include <QColorDialog>
#include <QFileDialog>
#include <QInputDialog>
#include <QMessageBox>

namespace LightGram {

LightGramStudioDialog::LightGramStudioDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("Studio_Title"));
    setMinimumSize(840, 580);
    m_editingTheme = ThemeEngine::instance().currentTheme();
    setupUi();
    updateControlsFromTheme(m_editingTheme);
    updatePreview();
}

void LightGramStudioDialog::setupUi() {
    QHBoxLayout* rootLayout = new QHBoxLayout(this);
    rootLayout->setContentsMargins(18, 18, 18, 18);
    rootLayout->setSpacing(20);

    // Left Column: Controls & Presets
    QVBoxLayout* leftCol = new QVBoxLayout();
    leftCol->setSpacing(12);

    QLabel* headerLbl = new QLabel(trL("Studio_Title"), this);
    headerLbl->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    leftCol->addWidget(headerLbl);

    QLabel* subLbl = new QLabel(trL("Studio_Subtitle"), this);
    subLbl->setStyleSheet("font-size: 12px; color: #888888;");
    leftCol->addWidget(subLbl);

    // Preset selector
    QHBoxLayout* presetRow = new QHBoxLayout();
    presetRow->addWidget(new QLabel(trL("Studio_PresetThemes") + ":", this));
    m_themeCombo = new QComboBox(this);
    connect(m_themeCombo, &QComboBox::currentTextChanged, this, &LightGramStudioDialog::onThemePresetChanged);
    presetRow->addWidget(m_themeCombo, 1);
    leftCol->addLayout(presetRow);

    // Color Pickers Grid
    QGridLayout* colorGrid = new QGridLayout();
    colorGrid->setSpacing(8);

    colorGrid->addWidget(new QLabel(trL("Studio_PrimaryAccent") + ":", this), 0, 0);
    colorGrid->addWidget(createColorButton("Primary", m_editingTheme.primaryAccent, "primaryAccent"), 0, 1);

    colorGrid->addWidget(new QLabel(trL("Studio_SecondaryAccent") + ":", this), 0, 2);
    colorGrid->addWidget(createColorButton("Secondary", m_editingTheme.secondaryAccent, "secondaryAccent"), 0, 3);

    colorGrid->addWidget(new QLabel(trL("Studio_BgColor") + ":", this), 1, 0);
    colorGrid->addWidget(createColorButton("Background", m_editingTheme.windowBackground, "windowBackground"), 1, 1);

    colorGrid->addWidget(new QLabel(trL("Studio_SidebarColor") + ":", this), 1, 2);
    colorGrid->addWidget(createColorButton("Sidebar", m_editingTheme.sidebarBackground, "sidebarBackground"), 1, 3);

    colorGrid->addWidget(new QLabel(trL("Studio_IncomingBubble") + ":", this), 2, 0);
    colorGrid->addWidget(createColorButton("Incoming", m_editingTheme.incomingBubble, "incomingBubble"), 2, 1);

    colorGrid->addWidget(new QLabel(trL("Studio_OutgoingBubble") + ":", this), 2, 2);
    colorGrid->addWidget(createColorButton("Outgoing", m_editingTheme.outgoingBubble, "outgoingBubble"), 2, 3);

    colorGrid->addWidget(new QLabel(trL("Studio_TextColor") + ":", this), 3, 0);
    colorGrid->addWidget(createColorButton("Text", m_editingTheme.textPrimary, "textPrimary"), 3, 1);

    colorGrid->addWidget(new QLabel("Unread Badge:", this), 3, 2);
    colorGrid->addWidget(createColorButton("Badge", m_editingTheme.unreadBadge, "unreadBadge"), 3, 3);

    leftCol->addLayout(colorGrid);

    // Sliders: Corner Radius, Glass Opacity, Blur Intensity
    QGridLayout* sliderGrid = new QGridLayout();
    sliderGrid->setSpacing(8);

    sliderGrid->addWidget(new QLabel(trL("Studio_CornerRadius") + ":", this), 0, 0);
    m_radiusSlider = new QSlider(Qt::Horizontal, this);
    m_radiusSlider->setRange(8, 28);
    m_radiusSlider->setValue(m_editingTheme.cornerRadius);
    sliderGrid->addWidget(m_radiusSlider, 0, 1);
    m_radiusValLbl = new QLabel(QString("%1 px").arg(m_editingTheme.cornerRadius), this);
    sliderGrid->addWidget(m_radiusValLbl, 0, 2);

    sliderGrid->addWidget(new QLabel(trL("Studio_GlassOpacity") + ":", this), 1, 0);
    m_opacitySlider = new QSlider(Qt::Horizontal, this);
    m_opacitySlider->setRange(20, 100);
    m_opacitySlider->setValue((int)(m_editingTheme.glassOpacity * 100));
    sliderGrid->addWidget(m_opacitySlider, 1, 1);
    m_opacityValLbl = new QLabel(QString("%1%").arg((int)(m_editingTheme.glassOpacity * 100)), this);
    sliderGrid->addWidget(m_opacityValLbl, 1, 2);

    sliderGrid->addWidget(new QLabel(trL("Studio_BlurIntensity") + ":", this), 2, 0);
    m_blurSlider = new QSlider(Qt::Horizontal, this);
    m_blurSlider->setRange(0, 30);
    m_blurSlider->setValue(m_editingTheme.blurIntensity);
    sliderGrid->addWidget(m_blurSlider, 2, 1);
    m_blurValLbl = new QLabel(QString("%1").arg(m_editingTheme.blurIntensity), this);
    sliderGrid->addWidget(m_blurValLbl, 2, 2);

    connect(m_radiusSlider, &QSlider::valueChanged, this, &LightGramStudioDialog::onSliderValueChanged);
    connect(m_opacitySlider, &QSlider::valueChanged, this, &LightGramStudioDialog::onSliderValueChanged);
    connect(m_blurSlider, &QSlider::valueChanged, this, &LightGramStudioDialog::onSliderValueChanged);

    leftCol->addLayout(sliderGrid);

    // Management buttons row
    QHBoxLayout* actionsRow = new QHBoxLayout();
    QPushButton* dupBtn = new QPushButton(trL("Studio_Duplicate"), this);
    connect(dupBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onDuplicateTheme);
    actionsRow->addWidget(dupBtn);

    QPushButton* importBtn = new QPushButton(trL("Studio_Import"), this);
    connect(importBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onImportTheme);
    actionsRow->addWidget(importBtn);

    QPushButton* exportBtn = new QPushButton(trL("Studio_Export"), this);
    connect(exportBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onExportTheme);
    actionsRow->addWidget(exportBtn);

    QPushButton* delBtn = new QPushButton(trL("Delete"), this);
    delBtn->setStyleSheet("QPushButton { color: #FF3B30; }");
    connect(delBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onDeleteTheme);
    actionsRow->addWidget(delBtn);

    leftCol->addLayout(actionsRow);

    // Bottom action row
    QHBoxLayout* bottomRow = new QHBoxLayout();
    QPushButton* resetBtn = new QPushButton(trL("Studio_ResetDefaults"), this);
    connect(resetBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onResetDefaults);
    bottomRow->addWidget(resetBtn);

    bottomRow->addStretch();

    QPushButton* applyBtn = new QPushButton(trL("Apply"), this);
    applyBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(applyBtn, &QPushButton::clicked, this, &LightGramStudioDialog::onSaveTheme);
    bottomRow->addWidget(applyBtn);

    QPushButton* closeBtn = new QPushButton(trL("Close"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::accept);
    bottomRow->addWidget(closeBtn);

    leftCol->addLayout(bottomRow);
    rootLayout->addLayout(leftCol, 1);

    // Right Column: Live Preview Panel
    QVBoxLayout* rightCol = new QVBoxLayout();
    rightCol->addWidget(new QLabel(trL("Studio_LivePreview"), this));

    m_previewContainer = new QWidget(this);
    m_previewContainer->setFixedWidth(320);
    QVBoxLayout* pvLayout = new QVBoxLayout(m_previewContainer);
    pvLayout->setContentsMargins(16, 16, 16, 16);
    pvLayout->setSpacing(12);

    // Incoming Bubble Preview
    m_previewIncomingBubble = new QWidget(m_previewContainer);
    QVBoxLayout* inLayout = new QVBoxLayout(m_previewIncomingBubble);
    inLayout->addWidget(new QLabel("Pavel Durov", m_previewIncomingBubble));
    inLayout->addWidget(new QLabel("LightGram Liquid Glass feels amazing!", m_previewIncomingBubble));
    pvLayout->addWidget(m_previewIncomingBubble);

    // Outgoing Bubble Preview
    m_previewOutgoingBubble = new QWidget(m_previewContainer);
    QVBoxLayout* outLayout = new QVBoxLayout(m_previewOutgoingBubble);
    outLayout->addWidget(new QLabel("Indeed, full iOS 27 style on desktop.", m_previewOutgoingBubble));
    pvLayout->addWidget(m_previewOutgoingBubble);

    // Button & Badge Preview
    QHBoxLayout* uiRow = new QHBoxLayout();
    m_previewButton = new QPushButton("Action Button", m_previewContainer);
    uiRow->addWidget(m_previewButton);

    m_previewBadge = new QLabel("42", m_previewContainer);
    m_previewBadge->setAlignment(Qt::AlignCenter);
    uiRow->addWidget(m_previewBadge);
    pvLayout->addLayout(uiRow);

    pvLayout->addStretch();
    rightCol->addWidget(m_previewContainer, 1);
    rootLayout->addLayout(rightCol);

    populateThemesList();
}

QPushButton* LightGramStudioDialog::createColorButton(const QString& label, const QColor& initialColor, const QString& key) {
    QPushButton* btn = new QPushButton(this);
    btn->setFixedSize(60, 26);
    btn->setToolTip(label);
    btn->setStyleSheet(QString("background-color: %1; border: 1px solid #555555; border-radius: 6px;").arg(initialColor.name()));

    m_colorButtons[key] = btn;
    connect(btn, &QPushButton::clicked, [this, key]() {
        onColorButtonClicked(key);
    });
    return btn;
}

void LightGramStudioDialog::populateThemesList() {
    m_themeCombo->blockSignals(true);
    m_themeCombo->clear();
    auto themes = ThemeEngine::instance().allThemes();
    for (const auto& t : themes) {
        m_themeCombo->addItem(t.name);
    }
    m_themeCombo->setCurrentText(m_editingTheme.name);
    m_themeCombo->blockSignals(false);
}

void LightGramStudioDialog::onThemePresetChanged(const QString& name) {
    m_editingTheme = ThemeEngine::instance().getTheme(name);
    updateControlsFromTheme(m_editingTheme);
    updatePreview();
    ThemeEngine::instance().applyTheme(name);
}

void LightGramStudioDialog::onColorButtonClicked(const QString& tokenKey) {
    QColor current;
    if (tokenKey == "primaryAccent") current = m_editingTheme.primaryAccent;
    else if (tokenKey == "secondaryAccent") current = m_editingTheme.secondaryAccent;
    else if (tokenKey == "windowBackground") current = m_editingTheme.windowBackground;
    else if (tokenKey == "sidebarBackground") current = m_editingTheme.sidebarBackground;
    else if (tokenKey == "incomingBubble") current = m_editingTheme.incomingBubble;
    else if (tokenKey == "outgoingBubble") current = m_editingTheme.outgoingBubble;
    else if (tokenKey == "textPrimary") current = m_editingTheme.textPrimary;
    else if (tokenKey == "unreadBadge") current = m_editingTheme.unreadBadge;

    QColor chosen = QColorDialog::getColor(current, this, "Choose Color", QColorDialog::ShowAlphaChannel);
    if (!chosen.isValid()) return;

    if (tokenKey == "primaryAccent") m_editingTheme.primaryAccent = chosen;
    else if (tokenKey == "secondaryAccent") m_editingTheme.secondaryAccent = chosen;
    else if (tokenKey == "windowBackground") m_editingTheme.windowBackground = chosen;
    else if (tokenKey == "sidebarBackground") m_editingTheme.sidebarBackground = chosen;
    else if (tokenKey == "incomingBubble") m_editingTheme.incomingBubble = chosen;
    else if (tokenKey == "outgoingBubble") m_editingTheme.outgoingBubble = chosen;
    else if (tokenKey == "textPrimary") m_editingTheme.textPrimary = chosen;
    else if (tokenKey == "unreadBadge") m_editingTheme.unreadBadge = chosen;

    if (m_colorButtons.contains(tokenKey)) {
        m_colorButtons[tokenKey]->setStyleSheet(QString("background-color: %1; border: 1px solid #FFFFFF; border-radius: 6px;").arg(chosen.name()));
    }
    updatePreview();
}

void LightGramStudioDialog::onSliderValueChanged() {
    m_editingTheme.cornerRadius = m_radiusSlider->value();
    m_radiusValLbl->setText(QString("%1 px").arg(m_editingTheme.cornerRadius));

    m_editingTheme.glassOpacity = m_opacitySlider->value() / 100.0;
    m_opacityValLbl->setText(QString("%1%").arg(m_opacitySlider->value()));

    m_editingTheme.blurIntensity = m_blurSlider->value();
    m_blurValLbl->setText(QString("%1").arg(m_editingTheme.blurIntensity));

    updatePreview();
}

void LightGramStudioDialog::updateControlsFromTheme(const ThemeConfig& t) {
    if (m_colorButtons.contains("primaryAccent")) m_colorButtons["primaryAccent"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.primaryAccent.name()));
    if (m_colorButtons.contains("secondaryAccent")) m_colorButtons["secondaryAccent"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.secondaryAccent.name()));
    if (m_colorButtons.contains("windowBackground")) m_colorButtons["windowBackground"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.windowBackground.name()));
    if (m_colorButtons.contains("sidebarBackground")) m_colorButtons["sidebarBackground"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.sidebarBackground.name()));
    if (m_colorButtons.contains("incomingBubble")) m_colorButtons["incomingBubble"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.incomingBubble.name()));
    if (m_colorButtons.contains("outgoingBubble")) m_colorButtons["outgoingBubble"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.outgoingBubble.name()));
    if (m_colorButtons.contains("textPrimary")) m_colorButtons["textPrimary"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.textPrimary.name()));
    if (m_colorButtons.contains("unreadBadge")) m_colorButtons["unreadBadge"]->setStyleSheet(QString("background-color: %1; border: 1px solid #555; border-radius: 6px;").arg(t.unreadBadge.name()));

    m_radiusSlider->setValue(t.cornerRadius);
    m_opacitySlider->setValue((int)(t.glassOpacity * 100));
    m_blurSlider->setValue(t.blurIntensity);
}

void LightGramStudioDialog::updatePreview() {
    int r = m_editingTheme.cornerRadius;

    m_previewContainer->setStyleSheet(QString(
        "background-color: %1; border: 1px solid %2; border-radius: %3px;"
    ).arg(m_editingTheme.windowBackground.name()).arg(m_editingTheme.borderGraphite.name()).arg(r));

    m_previewIncomingBubble->setStyleSheet(QString(
        "background-color: %1; border: 1px solid %2; border-radius: %3px; color: %4; padding: 6px;"
    ).arg(m_editingTheme.incomingBubble.name()).arg(m_editingTheme.borderGraphite.name()).arg(r).arg(m_editingTheme.textPrimary.name()));

    m_previewOutgoingBubble->setStyleSheet(QString(
        "background-color: %1; border-radius: %2px; color: %3; padding: 6px;"
    ).arg(m_editingTheme.outgoingBubble.name()).arg(r).arg(m_editingTheme.outgoingText.name()));

    m_previewButton->setStyleSheet(QString(
        "background-color: %1; color: %2; border-radius: %3px; padding: 6px 12px; font-weight: bold;"
    ).arg(m_editingTheme.buttonBackground.name()).arg(m_editingTheme.buttonText.name()).arg(r / 2));

    m_previewBadge->setStyleSheet(QString(
        "background-color: %1; color: #000000; border-radius: 10px; padding: 2px 8px; font-weight: bold;"
    ).arg(m_editingTheme.unreadBadge.name()));
}

void LightGramStudioDialog::onSaveTheme() {
    ThemeEngine::instance().saveCustomTheme(m_editingTheme);
    ThemeEngine::instance().applyTheme(m_editingTheme.name);
    QMessageBox::information(this, "LightGram Studio", "Theme saved and applied successfully!");
}

void LightGramStudioDialog::onDuplicateTheme() {
    bool ok = false;
    QString newName = QInputDialog::getText(this, "Duplicate Theme", "Enter new theme name:", QLineEdit::Normal, m_editingTheme.name + " Copy", &ok);
    if (ok && !newName.trimmed().isEmpty()) {
        ThemeEngine::instance().duplicateTheme(m_editingTheme.name, newName.trimmed());
        populateThemesList();
        m_themeCombo->setCurrentText(newName.trimmed());
    }
}

void LightGramStudioDialog::onDeleteTheme() {
    if (m_editingTheme.isBuiltIn) {
        QMessageBox::warning(this, "LightGram Studio", "Cannot delete built-in themes.");
        return;
    }
    if (QMessageBox::question(this, "Delete Theme", "Are you sure you want to delete this custom theme?") == QMessageBox::Yes) {
        ThemeEngine::instance().deleteCustomTheme(m_editingTheme.name);
        populateThemesList();
    }
}

void LightGramStudioDialog::onImportTheme() {
    QString path = QFileDialog::getOpenFileName(this, "Import Theme", QDir::homePath(), "LightGram Themes (*.lightgram-theme *.json)");
    if (!path.isEmpty()) {
        if (ThemeEngine::instance().importThemeFromFile(path)) {
            populateThemesList();
            QMessageBox::information(this, "Import Theme", "Theme imported successfully!");
        } else {
            QMessageBox::critical(this, "Import Error", "Failed to parse theme file.");
        }
    }
}

void LightGramStudioDialog::onExportTheme() {
    QString path = QFileDialog::getSaveFileName(this, "Export Theme", QDir::homePath() + "/" + m_editingTheme.name + ".lightgram-theme", "LightGram Themes (*.lightgram-theme *.json)");
    if (!path.isEmpty()) {
        if (ThemeEngine::instance().exportThemeToFile(m_editingTheme.name, path)) {
            QMessageBox::information(this, "Export Theme", "Theme exported successfully!");
        } else {
            QMessageBox::critical(this, "Export Error", "Failed to write theme file.");
        }
    }
}

void LightGramStudioDialog::onResetDefaults() {
    onThemePresetChanged("LightGram Original");
}

} // namespace LightGram
