#include "NotesManager.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>

namespace LightGram {

NotesManager& NotesManager::instance() {
    static NotesManager inst;
    return inst;
}

NotesManager::NotesManager() {
    load();
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &NotesManager::checkReminders);
    m_timer->start(30000); // Check every 30s
}

QString NotesManager::notesFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir dir(configDir);
    if (!dir.exists()) dir.mkpath(".");
    return dir.filePath("lightgram_notes.json");
}

void NotesManager::load() {
    QMutexLocker locker(&m_mutex);
    QFile file(notesFilePath());
    if (!file.open(QIODevice::ReadOnly)) return;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;

    QJsonObject root = doc.object();
    m_notes.clear();
    m_reminders.clear();

    QJsonArray notesArr = root.value("notes").toArray();
    for (const auto& val : notesArr) {
        QJsonObject o = val.toObject();
        PersonalNote n;
        n.id = o["id"].toString();
        n.title = o["title"].toString();
        n.content = o["content"].toString();
        n.createdTimestamp = o["created"].toVariant().toLongLong();
        n.updatedTimestamp = o["updated"].toVariant().toLongLong();
        n.colorTag = o["color"].toString("#EDB400");
        n.linkedPeerId = o["linkedPeer"].toString().toLongLong();
        n.linkedMessageId = o["linkedMsg"].toInt();
        m_notes.append(n);
    }

    QJsonArray remArr = root.value("reminders").toArray();
    for (const auto& val : remArr) {
        QJsonObject o = val.toObject();
        MessageReminder r;
        r.id = o["id"].toString();
        r.messageId = o["msgId"].toInt();
        r.peerId = o["peerId"].toString().toLongLong();
        r.note = o["note"].toString();
        r.triggerTimestamp = o["trigger"].toVariant().toLongLong();
        r.isCompleted = o["completed"].toBool();
        r.chatTitle = o["chatTitle"].toString();
        m_reminders.append(r);
    }
}

void NotesManager::persist() {
    QFile file(notesFilePath());
    if (!file.open(QIODevice::WriteOnly)) return;

    QJsonObject root;
    QJsonArray notesArr;
    for (const auto& n : m_notes) {
        QJsonObject o;
        o["id"] = n.id;
        o["title"] = n.title;
        o["content"] = n.content;
        o["created"] = (qint64)n.createdTimestamp;
        o["updated"] = (qint64)n.updatedTimestamp;
        o["color"] = n.colorTag;
        o["linkedPeer"] = QString::number(n.linkedPeerId);
        o["linkedMsg"] = n.linkedMessageId;
        notesArr.append(o);
    }
    root["notes"] = notesArr;

    QJsonArray remArr;
    for (const auto& r : m_reminders) {
        QJsonObject o;
        o["id"] = r.id;
        o["msgId"] = r.messageId;
        o["peerId"] = QString::number(r.peerId);
        o["note"] = r.note;
        o["trigger"] = (qint64)r.triggerTimestamp;
        o["completed"] = r.isCompleted;
        o["chatTitle"] = r.chatTitle;
        remArr.append(o);
    }
    root["reminders"] = remArr;

    QJsonDocument doc(root);
    file.write(doc.toJson(QJsonDocument::Compact));
}

PersonalNote NotesManager::addNote(const QString& title, const QString& content,
                                   const QString& colorTag, int64_t linkedPeerId, int32_t linkedMessageId) {
    PersonalNote n;
    n.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    n.title = title;
    n.content = content;
    n.colorTag = colorTag.isEmpty() ? "#EDB400" : colorTag;
    n.createdTimestamp = QDateTime::currentSecsSinceEpoch();
    n.updatedTimestamp = n.createdTimestamp;
    n.linkedPeerId = linkedPeerId;
    n.linkedMessageId = linkedMessageId;

    {
        QMutexLocker locker(&m_mutex);
        m_notes.prepend(n);
        persist();
    }
    emit notesUpdated();
    return n;
}

bool NotesManager::updateNote(const QString& id, const QString& title, const QString& content) {
    QMutexLocker locker(&m_mutex);
    for (int i = 0; i < m_notes.size(); ++i) {
        if (m_notes[i].id == id) {
            m_notes[i].title = title;
            m_notes[i].content = content;
            m_notes[i].updatedTimestamp = QDateTime::currentSecsSinceEpoch();
            persist();
            emit notesUpdated();
            return true;
        }
    }
    return false;
}

bool NotesManager::deleteNote(const QString& id) {
    QMutexLocker locker(&m_mutex);
    for (int i = 0; i < m_notes.size(); ++i) {
        if (m_notes[i].id == id) {
            m_notes.removeAt(i);
            persist();
            emit notesUpdated();
            return true;
        }
    }
    return false;
}

QVector<PersonalNote> NotesManager::fetchAllNotes(const QString& searchQuery) const {
    QMutexLocker locker(&m_mutex);
    if (searchQuery.isEmpty()) return m_notes;

    QString q = searchQuery.trimmed().toLower();
    QVector<PersonalNote> filtered;
    for (const auto& n : m_notes) {
        if (n.title.toLower().contains(q) || n.content.toLower().contains(q)) {
            filtered.append(n);
        }
    }
    return filtered;
}

MessageReminder NotesManager::addReminder(int64_t peerId, int32_t messageId, const QString& note,
                                          int64_t triggerTimestamp, const QString& chatTitle) {
    MessageReminder r;
    r.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    r.peerId = peerId;
    r.messageId = messageId;
    r.note = note;
    r.triggerTimestamp = triggerTimestamp;
    r.isCompleted = false;
    r.chatTitle = chatTitle.isEmpty() ? "Chat" : chatTitle;

    {
        QMutexLocker locker(&m_mutex);
        m_reminders.prepend(r);
        persist();
    }
    emit remindersUpdated();
    return r;
}

bool NotesManager::setReminderCompleted(const QString& id, bool completed) {
    QMutexLocker locker(&m_mutex);
    for (int i = 0; i < m_reminders.size(); ++i) {
        if (m_reminders[i].id == id) {
            m_reminders[i].isCompleted = completed;
            persist();
            emit remindersUpdated();
            return true;
        }
    }
    return false;
}

bool NotesManager::deleteReminder(const QString& id) {
    QMutexLocker locker(&m_mutex);
    for (int i = 0; i < m_reminders.size(); ++i) {
        if (m_reminders[i].id == id) {
            m_reminders.removeAt(i);
            persist();
            emit remindersUpdated();
            return true;
        }
    }
    return false;
}

QVector<MessageReminder> NotesManager::fetchAllReminders() const {
    QMutexLocker locker(&m_mutex);
    return m_reminders;
}

void NotesManager::checkReminders() {
    int64_t now = QDateTime::currentSecsSinceEpoch();
    QVector<MessageReminder> triggered;
    {
        QMutexLocker locker(&m_mutex);
        for (const auto& r : m_reminders) {
            if (!r.isCompleted && r.triggerTimestamp <= now) {
                triggered.append(r);
            }
        }
    }

    for (const auto& r : triggered) {
        emit reminderTriggered(r);
    }
}

} // namespace LightGram
