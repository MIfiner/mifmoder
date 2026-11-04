#pragma once

#include <QDialog>
#include <QTabWidget>
#include <QListWidget>
#include <QLineEdit>
#include <QPushButton>
#include "../core/NotesManager.hpp"

namespace LightGram {

class NotesDialog : public QDialog {
    Q_OBJECT
public:
    explicit NotesDialog(QWidget* parent = nullptr);

private slots:
    void reloadData();
    void onNewNoteClicked();
    void onNewReminderClicked();
    void onNoteDoubleClicked(QListWidgetItem* item);
    void onReminderDoubleClicked(QListWidgetItem* item);

private:
    void setupUi();

    QTabWidget* m_tabWidget = nullptr;
    QLineEdit* m_searchEdit = nullptr;
    QListWidget* m_notesList = nullptr;
    QListWidget* m_remindersList = nullptr;
};

} // namespace LightGram
