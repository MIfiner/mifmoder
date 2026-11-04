#include "Settings.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QCryptographicHash>

namespace LightGram {

Settings& Settings::instance() {
    static Settings inst;
    return inst;
}

Settings::Settings() {
    load();
}

QString Settings::settingsFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir dir(configDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    return dir.filePath("lightgram_settings.json");
}

void Settings::load() {
    QMutexLocker locker(&m_mutex);
    QFile file(settingsFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        QJsonObject root = doc.object();
        m_ghostModeEnabled = root.value("ghostModeEnabled").toBool(false);
        m_suppressReadHistory = root.value("suppressReadHistory").toBool(true);
        m_suppressTyping = root.value("suppressTyping").toBool(true);
        m_suppressStoryViews = root.value("suppressStoryViews").toBool(true);
        m_markAsReadOnReply = root.value("markAsReadOnReply").toBool(true);

        m_spyModeEnabled = root.value("spyModeEnabled").toBool(true);
        m_saveDeletedMessages = root.value("saveDeletedMessages").toBool(true);
        m_saveEditHistory = root.value("saveEditHistory").toBool(true);
        m_retentionDaysTTL = root.value("retentionDaysTTL").toInt(30);

        m_passcodeLockArchive = root.value("passcodeLockArchive").toBool(false);
        m_passcodeLockMediaVault = root.value("passcodeLockMediaVault").toBool(false);
        m_masterPasscodeHash = root.value("masterPasscodeHash").toString();

        m_activeThemeName = root.value("activeThemeName").toString("LightGram Original");
        m_activeLogoTheme = root.value("activeLogoTheme").toString("AmberIcon");

        m_compactMode = root.value("compactMode").toBool(false);
        m_minimizeToTray = root.value("minimizeToTray").toBool(true);
        m_autostart = root.value("autostart").toBool(false);
        m_language = root.value("language").toString("en");
        m_statsLastPeriod = root.value("statsLastPeriod").toInt(0);
    }
}

void Settings::save() {
    QMutexLocker locker(&m_mutex);
    QFile file(settingsFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        return;
    }

    QJsonObject root;
    root["ghostModeEnabled"] = m_ghostModeEnabled;
    root["suppressReadHistory"] = m_suppressReadHistory;
    root["suppressTyping"] = m_suppressTyping;
    root["suppressStoryViews"] = m_suppressStoryViews;
    root["markAsReadOnReply"] = m_markAsReadOnReply;

    root["spyModeEnabled"] = m_spyModeEnabled;
    root["saveDeletedMessages"] = m_saveDeletedMessages;
    root["saveEditHistory"] = m_saveEditHistory;
    root["retentionDaysTTL"] = m_retentionDaysTTL;

    root["passcodeLockArchive"] = m_passcodeLockArchive;
    root["passcodeLockMediaVault"] = m_passcodeLockMediaVault;
    root["masterPasscodeHash"] = m_masterPasscodeHash;

    root["activeThemeName"] = m_activeThemeName;
    root["activeLogoTheme"] = m_activeLogoTheme;

    root["compactMode"] = m_compactMode;
    root["minimizeToTray"] = m_minimizeToTray;
    root["autostart"] = m_autostart;
    root["language"] = m_language;
    root["statsLastPeriod"] = m_statsLastPeriod;

    QJsonDocument doc(root);
    file.write(doc.toJson());
}

void Settings::setGhostModeEnabled(bool enabled) {
    {
        QMutexLocker locker(&m_mutex);
        m_ghostModeEnabled = enabled;
    }
    save();
    emit ghostModeChanged(enabled);
}

void Settings::setSuppressReadHistory(bool val) {
    { QMutexLocker locker(&m_mutex); m_suppressReadHistory = val; }
    save();
}

void Settings::setSuppressTyping(bool val) {
    { QMutexLocker locker(&m_mutex); m_suppressTyping = val; }
    save();
}

void Settings::setSuppressStoryViews(bool val) {
    { QMutexLocker locker(&m_mutex); m_suppressStoryViews = val; }
    save();
}

void Settings::setMarkAsReadOnReply(bool val) {
    { QMutexLocker locker(&m_mutex); m_markAsReadOnReply = val; }
    save();
}

void Settings::setSpyModeEnabled(bool enabled) {
    {
        QMutexLocker locker(&m_mutex);
        m_spyModeEnabled = enabled;
    }
    save();
    emit spyModeChanged(enabled);
}

void Settings::setSaveDeletedMessages(bool val) {
    { QMutexLocker locker(&m_mutex); m_saveDeletedMessages = val; }
    save();
}

void Settings::setSaveEditHistory(bool val) {
    { QMutexLocker locker(&m_mutex); m_saveEditHistory = val; }
    save();
}

void Settings::setRetentionDaysTTL(int days) {
    { QMutexLocker locker(&m_mutex); m_retentionDaysTTL = days; }
    save();
}

void Settings::setPasscodeLockArchive(bool val) {
    { QMutexLocker locker(&m_mutex); m_passcodeLockArchive = val; }
    save();
}

void Settings::setPasscodeLockMediaVault(bool val) {
    { QMutexLocker locker(&m_mutex); m_passcodeLockMediaVault = val; }
    save();
}

void Settings::setMasterPasscode(const QString& passcode) {
    QByteArray hash = QCryptographicHash::hash(passcode.toUtf8(), QCryptographicHash::Sha256).toHex();
    { QMutexLocker locker(&m_mutex); m_masterPasscodeHash = QString::fromUtf8(hash); }
    save();
}

bool Settings::checkMasterPasscode(const QString& passcode) const {
    QMutexLocker locker(&m_mutex);
    if (m_masterPasscodeHash.isEmpty()) {
        return true;
    }
    QByteArray hash = QCryptographicHash::hash(passcode.toUtf8(), QCryptographicHash::Sha256).toHex();
    return (m_masterPasscodeHash == QString::fromUtf8(hash));
}

void Settings::setActiveThemeName(const QString& theme) {
    { QMutexLocker locker(&m_mutex); m_activeThemeName = theme; }
    save();
    emit themeChanged(theme);
}

void Settings::setActiveLogoTheme(const QString& logo) {
    { QMutexLocker locker(&m_mutex); m_activeLogoTheme = logo; }
    save();
}

void Settings::setCompactMode(bool val) {
    { QMutexLocker locker(&m_mutex); m_compactMode = val; }
    save();
    emit compactModeChanged(val);
}

void Settings::setMinimizeToTray(bool val) {
    { QMutexLocker locker(&m_mutex); m_minimizeToTray = val; }
    save();
}

void Settings::setAutostart(bool val) {
    { QMutexLocker locker(&m_mutex); m_autostart = val; }
    save();
}

void Settings::setLanguage(const QString& lang) {
    { QMutexLocker locker(&m_mutex); m_language = lang; }
    save();
    emit languageChanged(lang);
}

void Settings::setStatsLastPeriod(int val) {
    { QMutexLocker locker(&m_mutex); m_statsLastPeriod = val; }
    save();
}

QJsonObject Settings::exportToJson() const {
    QMutexLocker locker(&m_mutex);
    QJsonObject obj;
    obj["ghostModeEnabled"] = m_ghostModeEnabled;
    obj["suppressReadHistory"] = m_suppressReadHistory;
    obj["suppressTyping"] = m_suppressTyping;
    obj["suppressStoryViews"] = m_suppressStoryViews;
    obj["markAsReadOnReply"] = m_markAsReadOnReply;
    obj["spyModeEnabled"] = m_spyModeEnabled;
    obj["saveDeletedMessages"] = m_saveDeletedMessages;
    obj["saveEditHistory"] = m_saveEditHistory;
    obj["retentionDaysTTL"] = m_retentionDaysTTL;
    obj["activeThemeName"] = m_activeThemeName;
    obj["activeLogoTheme"] = m_activeLogoTheme;
    obj["language"] = m_language;
    return obj;
}

bool Settings::importFromJson(const QJsonObject& obj) {
    {
        QMutexLocker locker(&m_mutex);
        if (obj.contains("ghostModeEnabled")) m_ghostModeEnabled = obj["ghostModeEnabled"].toBool();
        if (obj.contains("suppressReadHistory")) m_suppressReadHistory = obj["suppressReadHistory"].toBool();
        if (obj.contains("suppressTyping")) m_suppressTyping = obj["suppressTyping"].toBool();
        if (obj.contains("suppressStoryViews")) m_suppressStoryViews = obj["suppressStoryViews"].toBool();
        if (obj.contains("markAsReadOnReply")) m_markAsReadOnReply = obj["markAsReadOnReply"].toBool();
        if (obj.contains("spyModeEnabled")) m_spyModeEnabled = obj["spyModeEnabled"].toBool();
        if (obj.contains("saveDeletedMessages")) m_saveDeletedMessages = obj["saveDeletedMessages"].toBool();
        if (obj.contains("saveEditHistory")) m_saveEditHistory = obj["saveEditHistory"].toBool();
        if (obj.contains("retentionDaysTTL")) m_retentionDaysTTL = obj["retentionDaysTTL"].toInt();
        if (obj.contains("activeThemeName")) m_activeThemeName = obj["activeThemeName"].toString();
        if (obj.contains("activeLogoTheme")) m_activeLogoTheme = obj["activeLogoTheme"].toString();
        if (obj.contains("language")) m_language = obj["language"].toString();
    }
    save();
    emit ghostModeChanged(m_ghostModeEnabled);
    emit spyModeChanged(m_spyModeEnabled);
    emit themeChanged(m_activeThemeName);
    emit languageChanged(m_language);
    return true;
}

} // namespace LightGram
