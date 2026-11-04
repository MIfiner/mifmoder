#pragma once

#include <QDialog>
#include <QTableWidget>
#include <QPushButton>
#include <QLabel>

namespace LightGram {

class DiagnosticsDialog : public QDialog {
    Q_OBJECT
public:
    explicit DiagnosticsDialog(QWidget* parent = nullptr);

private slots:
    void onPingAllClicked();
    void onDcResult(int dcId, const QString& name, const QString& ip, int rttMs, bool ok);

private:
    void setupUi();

    QTableWidget* m_table = nullptr;
    QLabel* m_statusLabel = nullptr;
    QPushButton* m_pingBtn = nullptr;
};

} // namespace LightGram
