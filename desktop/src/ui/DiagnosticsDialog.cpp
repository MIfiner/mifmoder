#include "DiagnosticsDialog.hpp"
#include "../core/TelegramClient.hpp"
#include "../core/Localization.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QHeaderView>

namespace LightGram {

DiagnosticsDialog::DiagnosticsDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("Diagnostics_Title"));
    setMinimumSize(620, 380);
    setupUi();

    connect(&TelegramClient::instance(), &TelegramClient::dcPingResult, this, &DiagnosticsDialog::onDcResult);
    onPingAllClicked();
}

void DiagnosticsDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(16, 16, 16, 16);
    mainLayout->setSpacing(12);

    QHBoxLayout* topRow = new QHBoxLayout();
    QLabel* title = new QLabel("📶 " + trL("Diagnostics_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    topRow->addWidget(title);

    topRow->addStretch();

    m_pingBtn = new QPushButton("⚡ " + trL("Diagnostics_PingAll"), this);
    m_pingBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(m_pingBtn, &QPushButton::clicked, this, &DiagnosticsDialog::onPingAllClicked);
    topRow->addWidget(m_pingBtn);

    mainLayout->addLayout(topRow);

    m_statusLabel = new QLabel("Testing live TCP RTT to Telegram MTProto Data Centers...", this);
    m_statusLabel->setStyleSheet("font-size: 12px; color: #888888;");
    mainLayout->addWidget(m_statusLabel);

    m_table = new QTableWidget(5, 4, this);
    m_table->setHorizontalHeaderLabels({ "DC ID", "Data Center Location", "IP Address", "RTT Latency" });
    m_table->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
    m_table->horizontalHeader()->setSectionResizeMode(2, QHeaderView::ResizeToContents);
    m_table->horizontalHeader()->setSectionResizeMode(3, QHeaderView::ResizeToContents);
    m_table->verticalHeader()->setVisible(false);
    m_table->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_table->setStyleSheet(
        "QTableWidget { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; gridline-color: rgba(255,255,255,0.05); } "
        "QHeaderView::section { background: rgba(255,255,255,0.08); padding: 6px; font-weight: bold; border: none; }"
    );

    struct DcEntry { int id; QString name; QString ip; };
    QVector<DcEntry> dcs = {
        { 1, trL("Diagnostics_DC1"), "149.154.175.50" },
        { 2, trL("Diagnostics_DC2"), "149.154.167.51" },
        { 3, trL("Diagnostics_DC3"), "149.154.175.100" },
        { 4, trL("Diagnostics_DC4"), "149.154.167.91" },
        { 5, trL("Diagnostics_DC5"), "91.108.56.130" }
    };

    for (int i = 0; i < dcs.size(); ++i) {
        m_table->setItem(i, 0, new QTableWidgetItem(QString("DC %1").arg(dcs[i].id)));
        m_table->setItem(i, 1, new QTableWidgetItem(dcs[i].name));
        m_table->setItem(i, 2, new QTableWidgetItem(dcs[i].ip));
        m_table->setItem(i, 3, new QTableWidgetItem("Pinging..."));
    }

    mainLayout->addWidget(m_table, 1);

    QHBoxLayout* botRow = new QHBoxLayout();
    botRow->addStretch();
    QPushButton* closeBtn = new QPushButton(trL("Close"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::accept);
    botRow->addWidget(closeBtn);
    mainLayout->addLayout(botRow);
}

void DiagnosticsDialog::onPingAllClicked() {
    m_statusLabel->setText("Pinging all 5 Telegram MTProto data centers...");
    for (int i = 0; i < 5; ++i) {
        m_table->setItem(i, 3, new QTableWidgetItem("Measuring..."));
    }
    TelegramClient::instance().pingDataCenters();
}

void DiagnosticsDialog::onDcResult(int dcId, const QString& name, const QString& ip, int rttMs, bool ok) {
    Q_UNUSED(name);
    Q_UNUSED(ip);
    int row = dcId - 1;
    if (row >= 0 && row < 5) {
        QString text = ok ? QString("🟢 %1 ms").arg(rttMs) : "🔴 Timeout";
        m_table->setItem(row, 3, new QTableWidgetItem(text));
    }
    m_statusLabel->setText("Ping measurement complete. Direct MTProto connection verified.");
}

} // namespace LightGram
