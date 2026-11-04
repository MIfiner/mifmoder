#pragma once

#include <QDialog>
#include <QGridLayout>
#include <QPushButton>

namespace LightGram {

class ControlCenterDialog : public QDialog {
    Q_OBJECT
public:
    explicit ControlCenterDialog(QWidget* parent = nullptr);

signals:
    void openStudioRequested();
    void openSpyArchiveRequested();
    void openStatisticsRequested();
    void openMediaVaultRequested();
    void openCircleStudioRequested();
    void openSmartFoldersRequested();
    void openNotesRequested();
    void openPrivacyRequested();
    void openDiagnosticsRequested();

private:
    void setupUi();
    QPushButton* createTile(const QString& icon, const QString& title, const QString& subtitle);
};

} // namespace LightGram
