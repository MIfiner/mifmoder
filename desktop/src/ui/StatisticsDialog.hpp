#pragma once

#include <QDialog>
#include <QComboBox>
#include <QLabel>
#include <QPushButton>
#include <QScrollArea>
#include <QVBoxLayout>
#include "../core/StatisticsManager.hpp"

namespace LightGram {

class StatisticsDialog : public QDialog {
    Q_OBJECT
public:
    explicit StatisticsDialog(QWidget* parent = nullptr);

private slots:
    void onPeriodChanged(int index);
    void onExportImage();
    void onExportReport();

private:
    void setupUi();
    void renderDashboard(const StatisticsSnapshot& s);
    QWidget* createMetricCard(const QString& title, const QString& value, const QString& subtitle = QString());
    QWidget* createHourlyChartWidget(const QVector<int>& hourly);
    QWidget* createDailyChartWidget(const QVector<QString>& labels, const QVector<int>& counts);

    QComboBox* m_periodCombo = nullptr;
    QScrollArea* m_scrollArea = nullptr;
    QWidget* m_contentWidget = nullptr;
    QVBoxLayout* m_contentLayout = nullptr;
};

} // namespace LightGram
