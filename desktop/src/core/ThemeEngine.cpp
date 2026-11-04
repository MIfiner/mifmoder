#include "ThemeEngine.hpp"
#include "Settings.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QApplication>

namespace LightGram {

QJsonObject ThemeConfig::toJson() const {
    QJsonObject o;
    o["name"] = name;
    o["isBuiltIn"] = isBuiltIn;
    o["isDark"] = isDark;
    o["primaryAccent"] = primaryAccent.name(QColor::HexArgb);
    o["secondaryAccent"] = secondaryAccent.name(QColor::HexArgb);
    o["windowBackground"] = windowBackground.name(QColor::HexArgb);
    o["sidebarBackground"] = sidebarBackground.name(QColor::HexArgb);
    o["cardSurface"] = cardSurface.name(QColor::HexArgb);
    o["cardElevated"] = cardElevated.name(QColor::HexArgb);
    o["borderGraphite"] = borderGraphite.name(QColor::HexArgb);
    o["dividerColor"] = dividerColor.name(QColor::HexArgb);
    o["incomingBubble"] = incomingBubble.name(QColor::HexArgb);
    o["outgoingBubble"] = outgoingBubble.name(QColor::HexArgb);
    o["outgoingText"] = outgoingText.name(QColor::HexArgb);
    o["deletedRed"] = deletedRed.name(QColor::HexArgb);
    o["deletedRedSurface"] = deletedRedSurface.name(QColor::HexArgb);
    o["editedYellow"] = editedYellow.name(QColor::HexArgb);
    o["editedYellowSurface"] = editedYellowSurface.name(QColor::HexArgb);
    o["textPrimary"] = textPrimary.name(QColor::HexArgb);
    o["textSecondary"] = textSecondary.name(QColor::HexArgb);
    o["unreadBadge"] = unreadBadge.name(QColor::HexArgb);
    o["buttonBackground"] = buttonBackground.name(QColor::HexArgb);
    o["buttonText"] = buttonText.name(QColor::HexArgb);
    o["iconTint"] = iconTint.name(QColor::HexArgb);
    o["cornerRadius"] = cornerRadius;
    o["glassOpacity"] = glassOpacity;
    o["blurIntensity"] = blurIntensity;
    o["wallpaperPath"] = wallpaperPath;
    return o;
}

ThemeConfig ThemeConfig::fromJson(const QJsonObject& o) {
    ThemeConfig t;
    t.name = o["name"].toString();
    t.isBuiltIn = o["isBuiltIn"].toBool(false);
    t.isDark = o["isDark"].toBool(true);
    if (o.contains("primaryAccent")) t.primaryAccent = QColor(o["primaryAccent"].toString());
    if (o.contains("secondaryAccent")) t.secondaryAccent = QColor(o["secondaryAccent"].toString());
    if (o.contains("windowBackground")) t.windowBackground = QColor(o["windowBackground"].toString());
    if (o.contains("sidebarBackground")) t.sidebarBackground = QColor(o["sidebarBackground"].toString());
    if (o.contains("cardSurface")) t.cardSurface = QColor(o["cardSurface"].toString());
    if (o.contains("cardElevated")) t.cardElevated = QColor(o["cardElevated"].toString());
    if (o.contains("borderGraphite")) t.borderGraphite = QColor(o["borderGraphite"].toString());
    if (o.contains("dividerColor")) t.dividerColor = QColor(o["dividerColor"].toString());
    if (o.contains("incomingBubble")) t.incomingBubble = QColor(o["incomingBubble"].toString());
    if (o.contains("outgoingBubble")) t.outgoingBubble = QColor(o["outgoingBubble"].toString());
    if (o.contains("outgoingText")) t.outgoingText = QColor(o["outgoingText"].toString());
    if (o.contains("deletedRed")) t.deletedRed = QColor(o["deletedRed"].toString());
    if (o.contains("deletedRedSurface")) t.deletedRedSurface = QColor(o["deletedRedSurface"].toString());
    if (o.contains("editedYellow")) t.editedYellow = QColor(o["editedYellow"].toString());
    if (o.contains("editedYellowSurface")) t.editedYellowSurface = QColor(o["editedYellowSurface"].toString());
    if (o.contains("textPrimary")) t.textPrimary = QColor(o["textPrimary"].toString());
    if (o.contains("textSecondary")) t.textSecondary = QColor(o["textSecondary"].toString());
    if (o.contains("unreadBadge")) t.unreadBadge = QColor(o["unreadBadge"].toString());
    if (o.contains("buttonBackground")) t.buttonBackground = QColor(o["buttonBackground"].toString());
    if (o.contains("buttonText")) t.buttonText = QColor(o["buttonText"].toString());
    if (o.contains("iconTint")) t.iconTint = QColor(o["iconTint"].toString());
    if (o.contains("cornerRadius")) t.cornerRadius = o["cornerRadius"].toInt(16);
    if (o.contains("glassOpacity")) t.glassOpacity = o["glassOpacity"].toDouble(0.85);
    if (o.contains("blurIntensity")) t.blurIntensity = o["blurIntensity"].toInt(18);
    if (o.contains("wallpaperPath")) t.wallpaperPath = o["wallpaperPath"].toString();
    return t;
}

ThemeEngine& ThemeEngine::instance() {
    static ThemeEngine inst;
    return inst;
}

ThemeEngine::ThemeEngine() {
    initBuiltInThemes();
    loadCustomThemes();

    QString savedName = Settings::instance().activeThemeName();
    applyTheme(savedName);
}

void ThemeEngine::initBuiltInThemes() {
    // 1. LightGram Original
    {
        ThemeConfig t;
        t.name = "LightGram Original";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xED, 0xB4, 0x00); // Amber
        t.secondaryAccent = QColor(0xFF, 0xC7, 0x00);
        t.windowBackground = QColor(0x00, 0x00, 0x00);
        t.sidebarBackground = QColor(0x12, 0x12, 0x14);
        t.cardSurface = QColor(0x1C, 0x1C, 0x1E);
        t.cardElevated = QColor(0x25, 0x25, 0x28);
        t.incomingBubble = QColor(0x1C, 0x1C, 0x1E);
        t.outgoingBubble = QColor(0xED, 0xB4, 0x00);
        t.outgoingText = QColor(0x00, 0x00, 0x00);
        t.unreadBadge = QColor(0xED, 0xB4, 0x00);
        t.iconTint = QColor(0xED, 0xB4, 0x00);
        m_builtInThemes[t.name] = t;
    }

    // 2. AMOLED Black
    {
        ThemeConfig t;
        t.name = "AMOLED Black";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xFF, 0xCC, 0x00);
        t.secondaryAccent = QColor(0xFF, 0xDE, 0x59);
        t.windowBackground = QColor(0x00, 0x00, 0x00);
        t.sidebarBackground = QColor(0x05, 0x05, 0x07);
        t.cardSurface = QColor(0x10, 0x10, 0x12);
        t.cardElevated = QColor(0x18, 0x18, 0x1B);
        t.incomingBubble = QColor(0x14, 0x14, 0x16);
        t.outgoingBubble = QColor(0xFF, 0xCC, 0x00);
        t.outgoingText = QColor(0x00, 0x00, 0x00);
        t.unreadBadge = QColor(0xFF, 0xCC, 0x00);
        t.iconTint = QColor(0xFF, 0xCC, 0x00);
        m_builtInThemes[t.name] = t;
    }

    // 3. Midnight
    {
        ThemeConfig t;
        t.name = "Midnight";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0x4A, 0x69, 0xFF);
        t.secondaryAccent = QColor(0x70, 0x8A, 0xFF);
        t.windowBackground = QColor(0x08, 0x0C, 0x16);
        t.sidebarBackground = QColor(0x0E, 0x14, 0x24);
        t.cardSurface = QColor(0x15, 0x1E, 0x33);
        t.cardElevated = QColor(0x1C, 0x28, 0x44);
        t.incomingBubble = QColor(0x15, 0x1E, 0x33);
        t.outgoingBubble = QColor(0x3B, 0x5B, 0xDB);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0x4A, 0x69, 0xFF);
        t.iconTint = QColor(0x70, 0x8A, 0xFF);
        m_builtInThemes[t.name] = t;
    }

    // 4. Graphite
    {
        ThemeConfig t;
        t.name = "Graphite";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xD4, 0xD4, 0xD8);
        t.secondaryAccent = QColor(0xA1, 0xA1, 0xAA);
        t.windowBackground = QColor(0x18, 0x18, 0x1B);
        t.sidebarBackground = QColor(0x20, 0x20, 0x23);
        t.cardSurface = QColor(0x27, 0x27, 0x2A);
        t.cardElevated = QColor(0x32, 0x32, 0x36);
        t.incomingBubble = QColor(0x27, 0x27, 0x2A);
        t.outgoingBubble = QColor(0x3F, 0x3F, 0x46);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0xE4, 0xE4, 0xE7);
        t.iconTint = QColor(0xD4, 0xD4, 0xD8);
        m_builtInThemes[t.name] = t;
    }

    // 5. Arctic
    {
        ThemeConfig t;
        t.name = "Arctic";
        t.isBuiltIn = true;
        t.isDark = false;
        t.primaryAccent = QColor(0x00, 0x7A, 0xFF);
        t.secondaryAccent = QColor(0x5A, 0xC8, 0xFA);
        t.windowBackground = QColor(0xF0, 0xF4, 0xF8);
        t.sidebarBackground = QColor(0xE2, 0xEA, 0xF2);
        t.cardSurface = QColor(0xFF, 0xFF, 0xFF);
        t.cardElevated = QColor(0xFA, 0xFB, 0xFD);
        t.borderGraphite = QColor(0xD0, 0xD8, 0xE2);
        t.dividerColor = QColor(0xDC, 0xE4, 0xEE);
        t.incomingBubble = QColor(0xFF, 0xFF, 0xFF);
        t.outgoingBubble = QColor(0x00, 0x7A, 0xFF);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.textPrimary = QColor(0x1C, 0x1E, 0x21);
        t.textSecondary = QColor(0x6A, 0x72, 0x7D);
        t.unreadBadge = QColor(0x00, 0x7A, 0xFF);
        t.buttonBackground = QColor(0xE2, 0xEA, 0xF2);
        t.buttonText = QColor(0x1C, 0x1E, 0x21);
        t.iconTint = QColor(0x00, 0x7A, 0xFF);
        m_builtInThemes[t.name] = t;
    }

    // 6. Emerald
    {
        ThemeConfig t;
        t.name = "Emerald";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0x2E, 0xCC, 0x71);
        t.secondaryAccent = QColor(0x58, 0xD6, 0x8D);
        t.windowBackground = QColor(0x07, 0x13, 0x0B);
        t.sidebarBackground = QColor(0x0D, 0x21, 0x14);
        t.cardSurface = QColor(0x13, 0x2D, 0x1C);
        t.cardElevated = QColor(0x1A, 0x3B, 0x25);
        t.incomingBubble = QColor(0x13, 0x2D, 0x1C);
        t.outgoingBubble = QColor(0x27, 0xAE, 0x60);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0x2E, 0xCC, 0x71);
        t.iconTint = QColor(0x2E, 0xCC, 0x71);
        m_builtInThemes[t.name] = t;
    }

    // 7. Violet
    {
        ThemeConfig t;
        t.name = "Violet";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xAF, 0x52, 0xDE);
        t.secondaryAccent = QColor(0xBF, 0x5A, 0xF2);
        t.windowBackground = QColor(0x11, 0x08, 0x1A);
        t.sidebarBackground = QColor(0x1B, 0x0E, 0x2A);
        t.cardSurface = QColor(0x27, 0x15, 0x3D);
        t.cardElevated = QColor(0x35, 0x1D, 0x52);
        t.incomingBubble = QColor(0x27, 0x15, 0x3D);
        t.outgoingBubble = QColor(0x8E, 0x44, 0xAD);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0xAF, 0x52, 0xDE);
        t.iconTint = QColor(0xBF, 0x5A, 0xF2);
        m_builtInThemes[t.name] = t;
    }

    // 8. Sunset
    {
        ThemeConfig t;
        t.name = "Sunset";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xFF, 0x5E, 0x3A);
        t.secondaryAccent = QColor(0xFF, 0x95, 0x00);
        t.windowBackground = QColor(0x16, 0x0B, 0x0B);
        t.sidebarBackground = QColor(0x23, 0x12, 0x12);
        t.cardSurface = QColor(0x32, 0x1B, 0x1B);
        t.cardElevated = QColor(0x42, 0x24, 0x24);
        t.incomingBubble = QColor(0x32, 0x1B, 0x1B);
        t.outgoingBubble = QColor(0xD3, 0x45, 0x24);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0xFF, 0x5E, 0x3A);
        t.iconTint = QColor(0xFF, 0x5E, 0x3A);
        m_builtInThemes[t.name] = t;
    }

    // 9. Crimson
    {
        ThemeConfig t;
        t.name = "Crimson";
        t.isBuiltIn = true;
        t.isDark = true;
        t.primaryAccent = QColor(0xFF, 0x3B, 0x30);
        t.secondaryAccent = QColor(0xFF, 0x45, 0x3A);
        t.windowBackground = QColor(0x14, 0x06, 0x07);
        t.sidebarBackground = QColor(0x21, 0x0A, 0x0C);
        t.cardSurface = QColor(0x30, 0x0F, 0x12);
        t.cardElevated = QColor(0x40, 0x15, 0x19);
        t.incomingBubble = QColor(0x30, 0x0F, 0x12);
        t.outgoingBubble = QColor(0xC0, 0x20, 0x20);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.unreadBadge = QColor(0xFF, 0x3B, 0x30);
        t.iconTint = QColor(0xFF, 0x3B, 0x30);
        m_builtInThemes[t.name] = t;
    }

    // 10. Pure White
    {
        ThemeConfig t;
        t.name = "Pure White";
        t.isBuiltIn = true;
        t.isDark = false;
        t.primaryAccent = QColor(0x00, 0x7A, 0xFF);
        t.secondaryAccent = QColor(0x34, 0xC7, 0x59);
        t.windowBackground = QColor(0xFF, 0xFF, 0xFF);
        t.sidebarBackground = QColor(0xF6, 0xF7, 0xF9);
        t.cardSurface = QColor(0xFE, 0xFE, 0xFE);
        t.cardElevated = QColor(0xF0, 0xF2, 0xF5);
        t.borderGraphite = QColor(0xE0, 0xE2, 0xE7);
        t.dividerColor = QColor(0xEB, 0xEE, 0xF2);
        t.incomingBubble = QColor(0xF0, 0xF2, 0xF5);
        t.outgoingBubble = QColor(0x00, 0x7A, 0xFF);
        t.outgoingText = QColor(0xFF, 0xFF, 0xFF);
        t.textPrimary = QColor(0x00, 0x00, 0x00);
        t.textSecondary = QColor(0x73, 0x73, 0x73);
        t.unreadBadge = QColor(0x00, 0x7A, 0xFF);
        t.buttonBackground = QColor(0xEB, 0xEE, 0xF2);
        t.buttonText = QColor(0x00, 0x00, 0x00);
        t.iconTint = QColor(0x00, 0x7A, 0xFF);
        m_builtInThemes[t.name] = t;
    }
}

QString ThemeEngine::customThemesFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir dir(configDir);
    if (!dir.exists()) dir.mkpath(".");
    return dir.filePath("custom_themes.json");
}

void ThemeEngine::loadCustomThemes() {
    QFile file(customThemesFilePath());
    if (!file.open(QIODevice::ReadOnly)) return;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return;

    m_customThemes.clear();
    QJsonArray arr = doc.array();
    for (const auto& val : arr) {
        ThemeConfig t = ThemeConfig::fromJson(val.toObject());
        m_customThemes[t.name] = t;
    }
}

void ThemeEngine::persistCustomThemes() {
    QFile file(customThemesFilePath());
    if (!file.open(QIODevice::WriteOnly)) return;

    QJsonArray arr;
    for (const auto& t : m_customThemes) {
        arr.append(t.toJson());
    }

    QJsonDocument doc(arr);
    file.write(doc.toJson(QJsonDocument::Indented));
}

QVector<ThemeConfig> ThemeEngine::allThemes() const {
    QVector<ThemeConfig> list;
    for (const auto& t : m_builtInThemes) list.append(t);
    for (const auto& t : m_customThemes) list.append(t);
    return list;
}

ThemeConfig ThemeEngine::getTheme(const QString& name) const {
    if (m_builtInThemes.contains(name)) return m_builtInThemes[name];
    if (m_customThemes.contains(name)) return m_customThemes[name];
    return m_builtInThemes.value("LightGram Original");
}

void ThemeEngine::applyTheme(const QString& name) {
    ThemeConfig target = getTheme(name);
    m_currentTheme = target;
    Settings::instance().setActiveThemeName(target.name);

    if (auto app = qobject_cast<QApplication*>(QCoreApplication::instance())) {
        app->setStyleSheet(generateStyleSheet(target));
    }
    emit themeApplied(target);
}

void ThemeEngine::updateCurrentTheme(const ThemeConfig& theme) {
    m_currentTheme = theme;
    if (m_customThemes.contains(theme.name)) {
        m_customThemes[theme.name] = theme;
        persistCustomThemes();
    }
    if (auto app = qobject_cast<QApplication*>(QCoreApplication::instance())) {
        app->setStyleSheet(generateStyleSheet(theme));
    }
    emit themeApplied(theme);
}

bool ThemeEngine::saveCustomTheme(const ThemeConfig& theme) {
    ThemeConfig t = theme;
    t.isBuiltIn = false;
    m_customThemes[t.name] = t;
    persistCustomThemes();
    emit themeListChanged();
    applyTheme(t.name);
    return true;
}

bool ThemeEngine::duplicateTheme(const QString& sourceName, const QString& newName) {
    ThemeConfig src = getTheme(sourceName);
    ThemeConfig dup = src;
    dup.name = newName;
    dup.isBuiltIn = false;
    m_customThemes[dup.name] = dup;
    persistCustomThemes();
    emit themeListChanged();
    applyTheme(dup.name);
    return true;
}

bool ThemeEngine::deleteCustomTheme(const QString& name) {
    if (m_builtInThemes.contains(name)) return false;
    if (!m_customThemes.contains(name)) return false;

    m_customThemes.remove(name);
    persistCustomThemes();
    emit themeListChanged();

    if (m_currentTheme.name == name) {
        applyTheme("LightGram Original");
    }
    return true;
}

bool ThemeEngine::exportThemeToFile(const QString& themeName, const QString& filePath) const {
    ThemeConfig t = getTheme(themeName);
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) return false;

    QJsonDocument doc(t.toJson());
    file.write(doc.toJson(QJsonDocument::Indented));
    return true;
}

bool ThemeEngine::importThemeFromFile(const QString& filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return false;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return false;

    ThemeConfig t = ThemeConfig::fromJson(doc.object());
    t.isBuiltIn = false;
    if (t.name.isEmpty()) t.name = "Imported Theme";

    m_customThemes[t.name] = t;
    persistCustomThemes();
    emit themeListChanged();
    applyTheme(t.name);
    return true;
}

QString ThemeEngine::generateStyleSheet(const ThemeConfig& t) const {
    QString qss;

    QString winBg = t.windowBackground.name();
    QString sideBg = t.sidebarBackground.name();
    QString cardBg = t.cardSurface.name();
    QString cardElev = t.cardElevated.name();
    QString borderCol = t.borderGraphite.name();
    QString primAccent = t.primaryAccent.name();
    QString textPrim = t.textPrimary.name();
    QString textSec = t.textSecondary.name();
    QString btnBg = t.buttonBackground.name();
    QString btnText = t.buttonText.name();
    int r = t.cornerRadius;

    qss += QString(
        "QMainWindow, QDialog {\n"
        "    background-color: %1;\n"
        "    color: %2;\n"
        "    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;\n"
        "    font-size: 13px;\n"
        "}\n\n"
        "QWidget {\n"
        "    color: %2;\n"
        "}\n\n"
        "QToolTip {\n"
        "    background-color: %3;\n"
        "    color: %2;\n"
        "    border: 1px solid %4;\n"
        "    border-radius: 8px;\n"
        "    padding: 6px 10px;\n"
        "}\n\n"
        "QScrollArea {\n"
        "    background: transparent;\n"
        "    border: none;\n"
        "}\n\n"
        "QScrollBar:vertical {\n"
        "    border: none;\n"
        "    background: transparent;\n"
        "    width: 8px;\n"
        "    margin: 0px;\n"
        "}\n"
        "QScrollBar::handle:vertical {\n"
        "    background: rgba(140, 140, 150, 0.35);\n"
        "    min-height: 24px;\n"
        "    border-radius: 4px;\n"
        "}\n"
        "QScrollBar::handle:vertical:hover {\n"
        "    background: rgba(180, 180, 190, 0.6);\n"
        "}\n"
        "QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {\n"
        "    height: 0px;\n"
        "}\n\n"
        "QPushButton {\n"
        "    background-color: %5;\n"
        "    color: %6;\n"
        "    border: 1px solid %4;\n"
        "    border-radius: %7px;\n"
        "    padding: 8px 16px;\n"
        "    font-weight: 600;\n"
        "}\n"
        "QPushButton:hover {\n"
        "    background-color: %8;\n"
        "    border: 1px solid %9;\n"
        "}\n"
        "QPushButton:pressed {\n"
        "    background-color: %9;\n"
        "    color: #000000;\n"
        "}\n\n"
        "QLineEdit, QTextEdit, QPlainTextEdit {\n"
        "    background-color: %3;\n"
        "    color: %2;\n"
        "    border: 1px solid %4;\n"
        "    border-radius: %7px;\n"
        "    padding: 8px 12px;\n"
        "    selection-background-color: %9;\n"
        "    selection-color: #000000;\n"
        "}\n"
        "QLineEdit:focus, QTextEdit:focus, QPlainTextEdit:focus {\n"
        "    border: 1px solid %9;\n"
        "}\n\n"
        "QTabWidget::pane {\n"
        "    border: 1px solid %4;\n"
        "    background-color: %3;\n"
        "    border-radius: %7px;\n"
        "}\n"
        "QTabBar::tab {\n"
        "    background-color: transparent;\n"
        "    color: %10;\n"
        "    padding: 8px 16px;\n"
        "    margin: 2px 4px;\n"
        "    border-radius: 8px;\n"
        "    font-weight: 500;\n"
        "}\n"
        "QTabBar::tab:selected {\n"
        "    background-color: %9;\n"
        "    color: #000000;\n"
        "    font-weight: 700;\n"
        "}\n"
        "QTabBar::tab:hover:!selected {\n"
        "    background-color: rgba(255, 255, 255, 0.08);\n"
        "    color: %2;\n"
        "}\n\n"
        "QComboBox {\n"
        "    background-color: %3;\n"
        "    color: %2;\n"
        "    border: 1px solid %4;\n"
        "    border-radius: %7px;\n"
        "    padding: 6px 12px;\n"
        "}\n"
        "QComboBox::drop-down {\n"
        "    subcontrol-origin: padding;\n"
        "    subcontrol-position: top right;\n"
        "    width: 24px;\n"
        "    border-left: 1px solid %4;\n"
        "}\n"
        "QComboBox QAbstractItemView {\n"
        "    background-color: %3;\n"
        "    color: %2;\n"
        "    selection-background-color: %9;\n"
        "    selection-color: #000000;\n"
        "    border: 1px solid %4;\n"
        "    border-radius: 8px;\n"
        "}\n\n"
        "QSlider::groove:horizontal {\n"
        "    height: 6px;\n"
        "    background: %4;\n"
        "    border-radius: 3px;\n"
        "}\n"
        "QSlider::sub-page:horizontal {\n"
        "    background: %9;\n"
        "    border-radius: 3px;\n"
        "}\n"
        "QSlider::handle:horizontal {\n"
        "    background: #FFFFFF;\n"
        "    border: 2px solid %9;\n"
        "    width: 16px;\n"
        "    margin-top: -5px;\n"
        "    margin-bottom: -5px;\n"
        "    border-radius: 8px;\n"
        "}\n\n"
        "QProgressBar {\n"
        "    border: 1px solid %4;\n"
        "    border-radius: 6px;\n"
        "    text-align: center;\n"
        "    background-color: %3;\n"
        "    color: %2;\n"
        "}\n"
        "QProgressBar::chunk {\n"
        "    background-color: %9;\n"
        "    border-radius: 5px;\n"
        "}\n"
    ).arg(winBg)                 // 1
     .arg(textPrim)              // 2
     .arg(cardBg)                // 3
     .arg(borderCol)             // 4
     .arg(btnBg)                 // 5
     .arg(btnText)               // 6
     .arg(r)                     // 7
     .arg(cardElev)              // 8
     .arg(primAccent)            // 9
     .arg(textSec);              // 10

    return qss;
}

} // namespace LightGram
