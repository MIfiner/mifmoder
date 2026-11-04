#pragma once

#include "Types.hpp"
#include <QObject>
#include <QVector>
#include <QMap>
#include <QTimer>
#include <QMutex>

namespace LightGram {

class NotesManager : public QObject {
    Q_OBJECT
public:
    static NotesManager& instance();

    void load();
    void persist();

    // Notes
    PersonalNote addNote(const QString& title, const QString& content,
                         const QString& colorTag = "#EDB400",
                         int64_t linkedPeerId = 0, int32_t linkedMessageId = 0);
    bool updateNote(const QString& id, const QString& title, const QString& content);
    bool deleteNote(const QString& id);
    QVector<PersonalNote> fetchAllNotes(const QString& searchQuery = "") const;

    // Reminders
    MessageReminder addReminder(int64_t peerId, int32_t messageId, const QString& note,
                                int64_t triggerTimestamp, const QString& chatTitle);
    bool setReminderCompleted(const QString& id, bool completed);
    bool deleteReminder(const QString& id);
    QVector<MessageReminder> fetchAllReminders() const;

signals:
    void notesUpdated();
    void remindersUpdated();
    void reminderTriggered(const MessageReminder& reminder);

private slots:
    void checkReminders();

private:
    NotesManager();
    QString notesFilePath() const;

    mutable QMutex m_mutex;
    QVector<PersonalNote> m_notes;
    QVector<MessageReminder> m_reminders;
    QTimer* m_timer = nullptr;
};

} // namespace LightGram
