#include "NotesDialog.hpp"
#include "../core/Localization.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QInputDialog>
#include <QMessageBox>
#include <QDateTime>

namespace LightGram {

NotesDialog::NotesDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("Notes_Title"));
    setMinimumSize(680, 480);
    setupUi();
    reloadData();

    connect(&NotesManager::instance(), &NotesManager::notesUpdated, this, &NotesDialog::reloadData);
    connect(&NotesManager::instance(), &NotesManager::remindersUpdated, this, &NotesDialog::reloadData);
}

void NotesDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(16, 16, 16, 16);
    mainLayout->setSpacing(12);

    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel("📝 " + trL("Notes_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    QPushButton* newNoteBtn = new QPushButton("＋ " + trL("Notes_NewNote"), this);
    newNoteBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(newNoteBtn, &QPushButton::clicked, this, &NotesDialog::onNewNoteClicked);
    topRow->addWidget(newNoteBtn);

    QPushButton* newRemBtn = new QPushButton("⏰ " + trL("Notes_NewReminder"), this);
    connect(newRemBtn, &QPushButton::clicked, this, &NotesDialog::onNewReminderClicked);
    topRow->addWidget(newRemBtn);

    mainLayout->addLayout(topRow);

    m_searchEdit = new QLineEdit(this);
    m_searchEdit->setPlaceholderText("Search notes...");
    connect(m_searchEdit, &QLineEdit::textChanged, this, &NotesDialog::reloadData);
    mainLayout->addWidget(m_searchEdit);

    m_tabWidget = new QTabWidget(this);

    m_notesList = new QListWidget(m_tabWidget);
    m_notesList->setStyleSheet("QListWidget { background: transparent; border: none; } QListWidget::item { padding: 10px; border-bottom: 1px solid rgba(255,255,255,0.06); }");
    connect(m_notesList, &QListWidget::itemDoubleClicked, this, &NotesDialog::onNoteDoubleClicked);
    m_tabWidget->addTab(m_notesList, trL("Notes_TabNotes"));

    m_remindersList = new QListWidget(m_tabWidget);
    m_remindersList->setStyleSheet("QListWidget { background: transparent; border: none; } QListWidget::item { padding: 10px; border-bottom: 1px solid rgba(255,255,255,0.06); }");
    connect(m_remindersList, &QListWidget::itemDoubleClicked, this, &NotesDialog::onReminderDoubleClicked);
    m_tabWidget->addTab(m_remindersList, trL("Notes_TabReminders"));

    mainLayout->addWidget(m_tabWidget, 1);
}

void NotesDialog::reloadData() {
    QString q = m_searchEdit ? m_searchEdit->text() : "";

    // Notes
    m_notesList->clear();
    auto notes = NotesManager::instance().fetchAllNotes(q);
    for (const auto& n : notes) {
        QString dateStr = QDateTime::fromSecsSinceEpoch(n.updatedTimestamp).toString("dd.MM.yyyy HH:mm");
        QString label = QString("📌 %1\n%2\nUpdated: %3")
                            .arg(n.title)
                            .arg(n.content.left(120))
                            .arg(dateStr);
        QListWidgetItem* item = new QListWidgetItem(label, m_notesList);
        item->setData(Qt::UserRole, n.id);
    }
    if (m_notesList->count() == 0) {
        new QListWidgetItem("No personal notes yet. Click \"New Note\" to create one.", m_notesList);
    }

    // Reminders
    m_remindersList->clear();
    auto reminders = NotesManager::instance().fetchAllReminders();
    for (const auto& r : reminders) {
        QString dateStr = QDateTime::fromSecsSinceEpoch(r.triggerTimestamp).toString("dd.MM.yyyy HH:mm");
        QString check = r.isCompleted ? "✅ [DONE] " : "⏰ [PENDING] ";
        QString label = QString("%1%2 • For chat: %3\nTime: %4")
                            .arg(check)
                            .arg(r.note)
                            .arg(r.chatTitle)
                            .arg(dateStr);
        QListWidgetItem* item = new QListWidgetItem(label, m_remindersList);
        item->setData(Qt::UserRole, r.id);
    }
    if (m_remindersList->count() == 0) {
        new QListWidgetItem("No message reminders scheduled.", m_remindersList);
    }
}

void NotesDialog::onNewNoteClicked() {
    bool ok1 = false;
    QString title = QInputDialog::getText(this, "New Note", "Title:", QLineEdit::Normal, "", &ok1);
    if (!ok1 || title.trimmed().isEmpty()) return;

    bool ok2 = false;
    QString content = QInputDialog::getMultiLineText(this, "New Note", "Content:", "", &ok2);
    if (!ok2) return;

    NotesManager::instance().addNote(title.trimmed(), content.trimmed());
    reloadData();
}

void NotesDialog::onNewReminderClicked() {
    bool ok = false;
    QString note = QInputDialog::getText(this, "New Reminder", "Reminder Note:", QLineEdit::Normal, "Check urgent documents", &ok);
    if (!ok || note.trimmed().isEmpty()) return;

    int64_t triggerTime = QDateTime::currentSecsSinceEpoch() + 3600; // in 1 hour
    NotesManager::instance().addReminder(0, 0, note.trimmed(), triggerTime, "General");
    reloadData();
}

void NotesDialog::onNoteDoubleClicked(QListWidgetItem* item) {
    if (!item) return;
    QString id = item->data(Qt::UserRole).toString();
    if (id.isEmpty()) return;

    for (const auto& n : NotesManager::instance().fetchAllNotes()) {
        if (n.id == id) {
            QMessageBox box(this);
            box.setWindowTitle(n.title);
            box.setText(n.content);
            QPushButton* editBtn = box.addButton("Edit", QMessageBox::ActionRole);
            QPushButton* delBtn = box.addButton("Delete", QMessageBox::DestructiveRole);
            box.addButton(QMessageBox::Close);
            box.exec();

            if (box.clickedButton() == editBtn) {
                bool ok = false;
                QString newContent = QInputDialog::getMultiLineText(this, "Edit Note", "Content:", n.content, &ok);
                if (ok) {
                    NotesManager::instance().updateNote(n.id, n.title, newContent);
                    reloadData();
                }
            } else if (box.clickedButton() == delBtn) {
                NotesManager::instance().deleteNote(n.id);
                reloadData();
            }
            break;
        }
    }
}

void NotesDialog::onReminderDoubleClicked(QListWidgetItem* item) {
    if (!item) return;
    QString id = item->data(Qt::UserRole).toString();
    if (id.isEmpty()) return;

    for (const auto& r : NotesManager::instance().fetchAllReminders()) {
        if (r.id == id) {
            QMessageBox box(this);
            box.setWindowTitle("Reminder Details");
            box.setText(QString("Note: %1\nChat: %2\nScheduled Time: %3\nStatus: %4")
                            .arg(r.note)
                            .arg(r.chatTitle)
                            .arg(QDateTime::fromSecsSinceEpoch(r.triggerTimestamp).toString())
                            .arg(r.isCompleted ? "Completed" : "Active"));

            QPushButton* toggleBtn = box.addButton(r.isCompleted ? "Mark Pending" : "Mark Done ✓", QMessageBox::ActionRole);
            QPushButton* delBtn = box.addButton("Delete", QMessageBox::DestructiveRole);
            box.addButton(QMessageBox::Close);
            box.exec();

            if (box.clickedButton() == toggleBtn) {
                NotesManager::instance().setReminderCompleted(r.id, !r.isCompleted);
                reloadData();
            } else if (box.clickedButton() == delBtn) {
                NotesManager::instance().deleteReminder(r.id);
                reloadData();
            }
            break;
        }
    }
}

} // namespace LightGram
