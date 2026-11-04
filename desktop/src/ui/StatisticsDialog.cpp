#include "StatisticsDialog.hpp"
#include "../core/Localization.hpp"
#include "../core/ThemeEngine.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QProgressBar>
#include <QPainter>
#include <QFileDialog>
#include <QMessageBox>

namespace LightGram {

StatisticsDialog::StatisticsDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("Statistics_Title"));
    setMinimumSize(820, 620);
    setupUi();
    onPeriodChanged(0);
}

void StatisticsDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(16, 16, 16, 16);
    mainLayout->setSpacing(12);

    // Header & Actions
    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel(trL("Statistics_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    m_periodCombo = new QComboBox(this);
    m_periodCombo->addItem(trL("Statistics_7Days"), 7);
    m_periodCombo->addItem(trL("Statistics_30Days"), 30);
    m_periodCombo->addItem(trL("Statistics_AllTime"), 0);
    connect(m_periodCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &StatisticsDialog::onPeriodChanged);
    topRow->addWidget(m_periodCombo);

    QPushButton* exportImgBtn = new QPushButton("🖼 " + trL("Statistics_ExportPNG"), this);
    connect(exportImgBtn, &QPushButton::clicked, this, &StatisticsDialog::onExportImage);
    topRow->addWidget(exportImgBtn);

    QPushButton* exportRepBtn = new QPushButton("📄 " + trL("Statistics_ExportPDF"), this);
    connect(exportRepBtn, &QPushButton::clicked, this, &StatisticsDialog::onExportReport);
    topRow->addWidget(exportRepBtn);

    mainLayout->addLayout(topRow);

    // Scroll Area
    m_scrollArea = new QScrollArea(this);
    m_scrollArea->setWidgetResizable(true);
    m_scrollArea->setStyleSheet("QScrollArea { background: transparent; border: none; }");

    m_contentWidget = new QWidget(m_scrollArea);
    m_contentWidget->setStyleSheet("background: transparent;");
    m_contentLayout = new QVBoxLayout(m_contentWidget);
    m_contentLayout->setContentsMargins(8, 8, 8, 8);
    m_contentLayout->setSpacing(16);

    m_scrollArea->setWidget(m_contentWidget);
    mainLayout->addWidget(m_scrollArea, 1);
}

void StatisticsDialog::onPeriodChanged(int index) {
    Q_UNUSED(index);
    int days = m_periodCombo->currentData().toInt();
    StatisticsSnapshot s = StatisticsManager::instance().getSnapshot(days);
    renderDashboard(s);
}

void StatisticsDialog::renderDashboard(const StatisticsSnapshot& s) {
    QLayoutItem* item;
    while ((item = m_contentLayout->takeAt(0)) != nullptr) {
        if (item->widget()) delete item->widget();
        delete item;
    }

    // 1. Overview Cards (4 Grid)
    QGridLayout* ovGrid = new QGridLayout();
    ovGrid->setSpacing(10);
    ovGrid->addWidget(createMetricCard("Total Messages", QString::number(s.totalCount), "In report period"), 0, 0);
    ovGrid->addWidget(createMetricCard("Sent Messages", QString::number(s.sentCount), "Outbound"), 0, 1);
    ovGrid->addWidget(createMetricCard("Received Messages", QString::number(s.receivedCount), "Inbound"), 0, 2);
    ovGrid->addWidget(createMetricCard("Active Chats", QString::number(s.activeChatsCount), "Dialogs"), 0, 3);
    m_contentLayout->addLayout(ovGrid);

    // 2. Media Breakdown Cards
    QGridLayout* medGrid = new QGridLayout();
    medGrid->setSpacing(10);
    medGrid->addWidget(createMetricCard("Photos", QString::number(s.photosCount), "Images"), 0, 0);
    medGrid->addWidget(createMetricCard("Videos", QString::number(s.videosCount), "Clips"), 0, 1);
    medGrid->addWidget(createMetricCard("Circles 1:1", QString::number(s.circlesCount), "Video Notes"), 0, 2);
    medGrid->addWidget(createMetricCard("Voice Notes", QString::number(s.voiceCount), "Audio"), 0, 3);
    medGrid->addWidget(createMetricCard("Documents", QString::number(s.filesCount), "Files"), 0, 4);
    m_contentLayout->addLayout(medGrid);

    // 3. Hourly Activity Chart
    QLabel* hTitle = new QLabel(trL("Statistics_HourlyHeader"), m_contentWidget);
    hTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #FFFFFF;");
    m_contentLayout->addWidget(hTitle);
    m_contentLayout->addWidget(createHourlyChartWidget(s.hourlyActivity));

    // 4. Daily Activity Trend Chart
    QLabel* dTitle = new QLabel(trL("Statistics_DailyHeader"), m_contentWidget);
    dTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #FFFFFF;");
    m_contentLayout->addWidget(dTitle);
    m_contentLayout->addWidget(createDailyChartWidget(s.dailyLabels, s.dailyCounts));

    // 5. Advanced Analytics & Top Chats
    QHBoxLayout* splitRow = new QHBoxLayout();

    // Left: Insights Card
    QWidget* insightCard = new QWidget(m_contentWidget);
    insightCard->setStyleSheet("background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px;");
    QVBoxLayout* il = new QVBoxLayout(insightCard);
    il->addWidget(new QLabel("💡 " + trL("Statistics_PeakHour") + ": " + s.peakHour));
    il->addWidget(new QLabel("📅 " + trL("Statistics_PeakDay") + ": " + s.peakDay));
    il->addWidget(new QLabel("📊 " + trL("Statistics_AvgDay") + ": " + QString::number(s.avgPerDay, 'f', 1)));
    il->addWidget(new QLabel("🔴 Preserved Deleted: " + QString::number(s.savedDeletedCount)));
    il->addWidget(new QLabel("🟡 Preserved Edits: " + QString::number(s.savedEditsCount)));
    il->addWidget(new QLabel("🛡 Media Vault Items: " + QString::number(s.vaultItemsCount) + " (" + s.vaultStorageFormatted + ")"));
    splitRow->addWidget(insightCard, 1);

    // Right: Top Chats
    QWidget* topCard = new QWidget(m_contentWidget);
    topCard->setStyleSheet("background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px;");
    QVBoxLayout* tl = new QVBoxLayout(topCard);
    tl->addWidget(new QLabel(trL("Statistics_TopChatsHeader")));

    const auto& theme = ThemeEngine::instance().currentTheme();
    for (const auto& c : s.topChats) {
        QHBoxLayout* row = new QHBoxLayout();
        QLabel* nameLbl = new QLabel(c.title, topCard);
        nameLbl->setFixedWidth(120);
        row->addWidget(nameLbl);

        QProgressBar* bar = new QProgressBar(topCard);
        bar->setRange(0, 100);
        bar->setValue((int)c.percentage);
        bar->setTextVisible(false);
        bar->setFixedHeight(10);
        bar->setStyleSheet(QString(
            "QProgressBar { background: rgba(255,255,255,0.08); border-radius: 5px; } "
            "QProgressBar::chunk { background: %1; border-radius: 5px; }"
        ).arg(theme.primaryAccent.name()));
        row->addWidget(bar, 1);

        QLabel* cntLbl = new QLabel(QString("%1 (%2%)").arg(c.messageCount).arg(QString::number(c.percentage, 'f', 0)), topCard);
        cntLbl->setFixedWidth(70);
        cntLbl->setAlignment(Qt::AlignRight);
        row->addWidget(cntLbl);
        tl->addLayout(row);
    }
    splitRow->addWidget(topCard, 1);

    m_contentLayout->addLayout(splitRow);
}

QWidget* StatisticsDialog::createMetricCard(const QString& title, const QString& value, const QString& subtitle) {
    QWidget* card = new QWidget(m_contentWidget);
    card->setStyleSheet("background: rgba(255, 255, 255, 0.04); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 12px; padding: 10px;");
    QVBoxLayout* vl = new QVBoxLayout(card);
    vl->setContentsMargins(12, 10, 12, 10);
    vl->setSpacing(4);

    QLabel* titleLbl = new QLabel(title, card);
    titleLbl->setStyleSheet("font-size: 11px; color: #888888; font-weight: 500;");
    vl->addWidget(titleLbl);

    QLabel* valLbl = new QLabel(value, card);
    valLbl->setStyleSheet("font-size: 22px; font-weight: bold; color: #EDB400;");
    vl->addWidget(valLbl);

    if (!subtitle.isEmpty()) {
        QLabel* subLbl = new QLabel(subtitle, card);
        subLbl->setStyleSheet("font-size: 10px; color: #666666;");
        vl->addWidget(subLbl);
    }

    return card;
}

QWidget* StatisticsDialog::createHourlyChartWidget(const QVector<int>& hourly) {
    class HourlyChart : public QWidget {
        QVector<int> m_data;
    public:
        HourlyChart(const QVector<int>& d, QWidget* parent = nullptr) : QWidget(parent), m_data(d) {
            setFixedHeight(110);
        }
    protected:
        void paintEvent(QPaintEvent*) override {
            QPainter p(this);
            p.setRenderHint(QPainter::Antialiasing);

            int maxVal = 1;
            for (int v : m_data) if (v > maxVal) maxVal = v;

            double w = (double)width() / 24.0;
            int h = height() - 20;

            for (int i = 0; i < 24; ++i) {
                double barH = (double)m_data[i] / (double)maxVal * (h - 10);
                QRectF barRect(i * w + 2, h - barH, w - 4, barH);

                p.setBrush(QColor(0xED, 0xB4, 0x00, m_data[i] == maxVal ? 255 : 180));
                p.setPen(Qt::NoPen);
                p.drawRoundedRect(barRect, 3, 3);

                if (i % 3 == 0) {
                    p.setPen(QColor(0x88, 0x88, 0x88));
                    p.drawText(QRectF(i * w, h + 2, w * 3, 16), Qt::AlignLeft, QString("%1h").arg(i));
                }
            }
        }
    };

    return new HourlyChart(hourly, m_contentWidget);
}

QWidget* StatisticsDialog::createDailyChartWidget(const QVector<QString>& labels, const QVector<int>& counts) {
    class DailyChart : public QWidget {
        QVector<QString> m_labels;
        QVector<int> m_counts;
    public:
        DailyChart(const QVector<QString>& l, const QVector<int>& c, QWidget* parent = nullptr)
            : QWidget(parent), m_labels(l), m_counts(c) {
            setFixedHeight(110);
        }
    protected:
        void paintEvent(QPaintEvent*) override {
            QPainter p(this);
            p.setRenderHint(QPainter::Antialiasing);

            int maxVal = 1;
            for (int v : m_counts) if (v > maxVal) maxVal = v;

            int n = m_counts.size();
            if (n == 0) return;

            double w = (double)width() / (double)n;
            int h = height() - 20;

            for (int i = 0; i < n; ++i) {
                double barH = (double)m_counts[i] / (double)maxVal * (h - 10);
                QRectF barRect(i * w + 6, h - barH, w - 12, barH);

                p.setBrush(QColor(0x2E, 0xCC, 0x71, 200));
                p.setPen(Qt::NoPen);
                p.drawRoundedRect(barRect, 4, 4);

                p.setPen(QColor(0xAA, 0xAA, 0xAA));
                p.drawText(QRectF(i * w, h + 2, w, 16), Qt::AlignCenter, m_labels.value(i));
            }
        }
    };

    return new DailyChart(labels, counts, m_contentWidget);
}

void StatisticsDialog::onExportImage() {
    QString path = QFileDialog::getSaveFileName(this, "Export Analytics Chart", QDir::homePath() + "/lightgram_analytics.png", "Images (*.png)");
    if (!path.isEmpty()) {
        QPixmap pix = m_contentWidget->grab();
        pix.save(path);
        QMessageBox::information(this, "Export", "Analytics chart exported successfully!");
    }
}

void StatisticsDialog::onExportReport() {
    int days = m_periodCombo->currentData().toInt();
    QString report = StatisticsManager::instance().exportReportText(days);

    QString path = QFileDialog::getSaveFileName(this, "Export Analytics Report", QDir::homePath() + "/lightgram_report.txt", "Text (*.txt)");
    if (!path.isEmpty()) {
        QFile file(path);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(report.toUtf8());
            QMessageBox::information(this, "Export", "Report successfully exported to text file!");
        }
    }
}

} // namespace LightGram
