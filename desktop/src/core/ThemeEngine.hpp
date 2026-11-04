#pragma once

#include <QObject>
#include <QColor>
#include <QString>
#include <QVector>
#include <QMap>
#include <QJsonObject>

namespace LightGram {

struct ThemeConfig {
    QString name;
    bool isBuiltIn = false;
    bool isDark = true;

    // Colors
    QColor primaryAccent = QColor(0xED, 0xB4, 0x00);      // Signature Amber / Electric Gold
    QColor secondaryAccent = QColor(0xFF, 0xC7, 0x00);
    QColor windowBackground = QColor(0x00, 0x00, 0x00);    // AMOLED Black
    QColor sidebarBackground = QColor(0x12, 0x12, 0x14);   // Deep Graphite
    QColor cardSurface = QColor(0x1C, 0x1C, 0x1E);         // Elevated Card
    QColor cardElevated = QColor(0x25, 0x25, 0x28);
    QColor borderGraphite = QColor(0x2C, 0x2C, 0x2E);
    QColor dividerColor = QColor(0x38, 0x38, 0x3A);

    // Messages
    QColor incomingBubble = QColor(0x1C, 0x1C, 0x1E);
    QColor outgoingBubble = QColor(0xEDB400);
    QColor outgoingText = QColor(0x00, 0x00, 0x00);

    // Spy Mode
    QColor deletedRed = QColor(0xFF, 0x3B, 0x30);
    QColor deletedRedSurface = QColor(0x2C, 0x14, 0x16);
    QColor editedYellow = QColor(0xFF, 0xB3, 0x00);
    QColor editedYellowSurface = QColor(0x2B, 0x23, 0x10);

    // Typography & UI
    QColor textPrimary = QColor(0xFF, 0xFF, 0xFF);
    QColor textSecondary = QColor(0x8E, 0x8E, 0x93);
    QColor unreadBadge = QColor(0xED, 0xB4, 0x00);
    QColor buttonBackground = QColor(0x25, 0x25, 0x28);
    QColor buttonText = QColor(0xFF, 0xFF, 0xFF);
    QColor iconTint = QColor(0xED, 0xB4, 0x00);

    // Glass & Geometry
    int cornerRadius = 16;       // 8 to 28
    double glassOpacity = 0.85;  // 0.2 to 1.0
    int blurIntensity = 18;      // 0 to 30
    QString wallpaperPath;

    QJsonObject toJson() const;
    static ThemeConfig fromJson(const QJsonObject& obj);
};

class ThemeEngine : public QObject {
    Q_OBJECT
public:
    static ThemeEngine& instance();

    const ThemeConfig& currentTheme() const { return m_currentTheme; }
    QString currentThemeName() const { return m_currentTheme.name; }

    void applyTheme(const QString& name);
    void updateCurrentTheme(const ThemeConfig& theme);

    QVector<ThemeConfig> allThemes() const;
    ThemeConfig getTheme(const QString& name) const;

    // Theme Management
    bool saveCustomTheme(const ThemeConfig& theme);
    bool duplicateTheme(const QString& sourceName, const QString& newName);
    bool deleteCustomTheme(const QString& name);
    bool exportThemeToFile(const QString& themeName, const QString& filePath) const;
    bool importThemeFromFile(const QString& filePath);

    // QSS generation
    QString generateStyleSheet(const ThemeConfig& theme) const;
    QString generateCurrentStyleSheet() const { return generateStyleSheet(m_currentTheme); }

signals:
    void themeApplied(const ThemeConfig& theme);
    void themeListChanged();

private:
    ThemeEngine();
    void initBuiltInThemes();
    void loadCustomThemes();
    void persistCustomThemes();
    QString customThemesFilePath() const;

    ThemeConfig m_currentTheme;
    QMap<QString, ThemeConfig> m_builtInThemes;
    QMap<QString, ThemeConfig> m_customThemes;
};

} // namespace LightGram
