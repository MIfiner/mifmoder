#pragma once

#include <QString>
#include <QMap>
#include <QObject>

namespace LightGram {

enum class Language {
    English,
    Russian,
    Polish
};

class Localization : public QObject {
    Q_OBJECT
public:
    static Localization& instance();

    Language currentLanguage() const { return m_currentLanguage; }
    QString languageCode() const;
    void setLanguage(Language lang);
    void setLanguageByCode(const QString& code);

    QString get(const QString& key) const;
    QString get(const QString& key, const QString& defaultVal) const;

signals:
    void languageChanged(Language lang);

private:
    Localization();
    void initStrings();

    Language m_currentLanguage = Language::English;
    QMap<Language, QMap<QString, QString>> m_strings;
};

// Convenience helper
inline QString trL(const QString& key) {
    return Localization::instance().get(key);
}

} // namespace LightGram
