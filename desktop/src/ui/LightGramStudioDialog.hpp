#pragma once

#include <QDialog>
#include <QComboBox>
#include <QPushButton>
#include <QSlider>
#include <QLabel>
#include <QVBoxLayout>
#include "../core/ThemeEngine.hpp"

namespace LightGram {

class LightGramStudioDialog : public QDialog {
    Q_OBJECT
public:
    explicit LightGramStudioDialog(QWidget* parent = nullptr);

private slots:
    void onThemePresetChanged(const QString& name);
    void onColorButtonClicked(const QString& tokenKey);
    void onSliderValueChanged();
    void onSaveTheme();
    void onDuplicateTheme();
    void onDeleteTheme();
    void onImportTheme();
    void onExportTheme();
    void onResetDefaults();

private:
    void setupUi();
    void populateThemesList();
    void updateControlsFromTheme(const ThemeConfig& theme);
    void updatePreview();
    QPushButton* createColorButton(const QString& label, const QColor& initialColor, const QString& key);

    QComboBox* m_themeCombo = nullptr;
    QMap<QString, QPushButton*> m_colorButtons;

    QSlider* m_radiusSlider = nullptr;
    QLabel* m_radiusValLbl = nullptr;

    QSlider* m_opacitySlider = nullptr;
    QLabel* m_opacityValLbl = nullptr;

    QSlider* m_blurSlider = nullptr;
    QLabel* m_blurValLbl = nullptr;

    // Live preview widgets
    QWidget* m_previewContainer = nullptr;
    QWidget* m_previewIncomingBubble = nullptr;
    QWidget* m_previewOutgoingBubble = nullptr;
    QPushButton* m_previewButton = nullptr;
    QLabel* m_previewBadge = nullptr;

    ThemeConfig m_editingTheme;
};

} // namespace LightGram
