#pragma once

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QMutex>

namespace LightGram {

class Settings : public QObject {
    Q_OBJECT
public:
    static Settings& instance();

    void load();
    void save();

    // Ghost Mode
    bool isGhostModeEnabled() const { return m_ghostModeEnabled; }
    void setGhostModeEnabled(bool enabled);

    bool suppressReadHistory() const { return m_suppressReadHistory; }
    void setSuppressReadHistory(bool val);

    bool suppressTyping() const { return m_suppressTyping; }
    void setSuppressTyping(bool val);

    bool suppressStoryViews() const { return m_suppressStoryViews; }
    void setSuppressStoryViews(bool val);

    bool markAsReadOnReply() const { return m_markAsReadOnReply; }
    void setMarkAsReadOnReply(bool val);

    // Spy Mode
    bool isSpyModeEnabled() const { return m_spyModeEnabled; }
    void setSpyModeEnabled(bool enabled);

    bool saveDeletedMessages() const { return m_saveDeletedMessages; }
    void setSaveDeletedMessages(bool val);

    bool saveEditHistory() const { return m_saveEditHistory; }
    void setSaveEditHistory(bool val);

    int retentionDaysTTL() const { return m_retentionDaysTTL; }
    void setRetentionDaysTTL(int days);

    // Privacy & Security
    bool passcodeLockArchive() const { return m_passcodeLockArchive; }
    void setPasscodeLockArchive(bool val);

    bool passcodeLockMediaVault() const { return m_passcodeLockMediaVault; }
    void setPasscodeLockMediaVault(bool val);

    QString masterPasscodeHash() const { return m_masterPasscodeHash; }
    void setMasterPasscode(const QString& passcode);
    bool checkMasterPasscode(const QString& passcode) const;

    // Appearance & Themes
    QString activeThemeName() const { return m_activeThemeName; }
    void setActiveThemeName(const QString& theme);

    QString activeLogoTheme() const { return m_activeLogoTheme; }
    void setActiveLogoTheme(const QString& logo);

    // Desktop options
    bool compactMode() const { return m_compactMode; }
    void setCompactMode(bool val);

    bool minimizeToTray() const { return m_minimizeToTray; }
    void setMinimizeToTray(bool val);

    bool autostart() const { return m_autostart; }
    void setAutostart(bool val);

    QString language() const { return m_language; }
    void setLanguage(const QString& lang);

    int statsLastPeriod() const { return m_statsLastPeriod; }
    void setStatsLastPeriod(int val);

    // Export & Import Settings for iOS/Desktop synchronization
    QJsonObject exportToJson() const;
    bool importFromJson(const QJsonObject& obj);

signals:
    void ghostModeChanged(bool enabled);
    void spyModeChanged(bool enabled);
    void themeChanged(const QString& themeName);
    void languageChanged(const QString& lang);
    void compactModeChanged(bool compact);

private:
    Settings();
    QString settingsFilePath() const;

    mutable QMutex m_mutex;

    bool m_ghostModeEnabled = false;
    bool m_suppressReadHistory = true;
    bool m_suppressTyping = true;
    bool m_suppressStoryViews = true;
    bool m_markAsReadOnReply = true;

    bool m_spyModeEnabled = true;
    bool m_saveDeletedMessages = true;
    bool m_saveEditHistory = true;
    int m_retentionDaysTTL = 30;

    bool m_passcodeLockArchive = false;
    bool m_passcodeLockMediaVault = false;
    QString m_masterPasscodeHash;

    QString m_activeThemeName = "LightGram Original";
    QString m_activeLogoTheme = "AmberIcon";

    bool m_compactMode = false;
    bool m_minimizeToTray = true;
    bool m_autostart = false;
    QString m_language = "en";
    int m_statsLastPeriod = 0;
};

} // namespace LightGram
