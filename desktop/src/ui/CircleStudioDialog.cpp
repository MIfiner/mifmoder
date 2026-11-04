#include "CircleStudioDialog.hpp"
#include "../core/Localization.hpp"
#include "../core/MediaVaultManager.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QPainter>
#include <QPainterPath>
#include <QMessageBox>
#include <QFileInfo>

namespace LightGram {

CircleStudioDialog::CircleStudioDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("CircleStudio_Title"));
    setFixedSize(480, 560);
    setupUi();
}

void CircleStudioDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(20, 20, 20, 20);
    mainLayout->setSpacing(14);

    QLabel* title = new QLabel(trL("CircleStudio_Title"), this);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #FFFFFF;");
    title->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(title);

    QLabel* sub = new QLabel(trL("CircleStudio_Subtitle"), this);
    sub->setStyleSheet("font-size: 12px; color: #888888;");
    sub->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(sub);

    // Circular Viewport Widget
    class CircleMaskWidget : public QWidget {
    public:
        CircleMaskWidget(QWidget* parent = nullptr) : QWidget(parent) {
            setFixedSize(220, 220);
        }
    protected:
        void paintEvent(QPaintEvent*) override {
            QPainter p(this);
            p.setRenderHint(QPainter::Antialiasing);

            QRect r = rect().adjusted(6, 6, -6, -6);
            QPainterPath path;
            path.addEllipse(r);

            // Inner dark viewport
            p.fillPath(path, QColor(0x1C, 0x1C, 0x1E));

            // Gold accent ring
            QPen pen(QColor(0xED, 0xB4, 0x00), 3.0);
            p.setPen(pen);
            p.drawEllipse(r);

            // Icon in center
            p.setPen(QColor(0xFF, 0xFF, 0xFF, 180));
            p.setFont(QFont("sans-serif", 13, QFont::Bold));
            p.drawText(r, Qt::AlignCenter, "1:1 VIDEO NOTE");
        }
    };

    QHBoxLayout* centerCircleLayout = new QHBoxLayout();
    centerCircleLayout->addStretch();
    m_circleViewport = new CircleMaskWidget(this);
    centerCircleLayout->addWidget(m_circleViewport);
    centerCircleLayout->addStretch();
    mainLayout->addLayout(centerCircleLayout);

    // Controls
    QHBoxLayout* fileRow = new QHBoxLayout();
    m_videoPathEdit = new QLineEdit(this);
    m_videoPathEdit->setPlaceholderText("Select video file (.mp4, .mov)...");
    m_videoPathEdit->setReadOnly(true);
    fileRow->addWidget(m_videoPathEdit, 1);

    QPushButton* browseBtn = new QPushButton("Browse...", this);
    connect(browseBtn, &QPushButton::clicked, this, &CircleStudioDialog::onSelectVideo);
    fileRow->addWidget(browseBtn);
    mainLayout->addLayout(fileRow);

    // Duration / Trim Slider (up to 60s)
    QLabel* trimLbl = new QLabel("Duration / Crop (max 60s):", this);
    mainLayout->addWidget(trimLbl);

    m_trimSlider = new QSlider(Qt::Horizontal, this);
    m_trimSlider->setRange(1, 60);
    m_trimSlider->setValue(30);
    mainLayout->addWidget(m_trimSlider);

    m_statusLabel = new QLabel("Ready to convert", this);
    m_statusLabel->setAlignment(Qt::AlignCenter);
    m_statusLabel->setStyleSheet("font-size: 11px; color: #34C759;");
    mainLayout->addWidget(m_statusLabel);

    // Bottom action row
    QHBoxLayout* botRow = new QHBoxLayout();
    m_playBtn = new QPushButton("▶ " + trL("CircleStudio_PlayPreview"), this);
    connect(m_playBtn, &QPushButton::clicked, this, &CircleStudioDialog::onTogglePlay);
    botRow->addWidget(m_playBtn);

    QPushButton* saveBtn = new QPushButton("🛡 " + trL("CircleStudio_Save"), this);
    saveBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(saveBtn, &QPushButton::clicked, this, &CircleStudioDialog::onSaveToVault);
    botRow->addWidget(saveBtn);

    QPushButton* closeBtn = new QPushButton(trL("Close"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::accept);
    botRow->addWidget(closeBtn);

    mainLayout->addLayout(botRow);
}

void CircleStudioDialog::onSelectVideo() {
    QString f = QFileDialog::getOpenFileName(this, "Select Video", QDir::homePath(), "Videos (*.mp4 *.mov *.mkv)");
    if (!f.isEmpty()) {
        m_selectedVideoPath = f;
        m_videoPathEdit->setText(f);
        m_statusLabel->setText("Video loaded: " + QFileInfo(f).fileName());
    }
}

void CircleStudioDialog::onTogglePlay() {
    if (m_selectedVideoPath.isEmpty()) {
        QMessageBox::warning(this, "Circle Studio", "Please select a video file first.");
        return;
    }
    m_statusLabel->setText("Playing circular preview (1:1 aspect ratio)...");
}

void CircleStudioDialog::onSaveToVault() {
    if (m_selectedVideoPath.isEmpty()) {
        QMessageBox::warning(this, "Circle Studio", "Please select a video file first.");
        return;
    }

    QFileInfo fi(m_selectedVideoPath);
    bool ok = MediaVaultManager::instance().saveToVault(m_selectedVideoPath, fi.fileName(), "circle", 0, 0, "Circle Studio", "You");
    if (ok) {
        QMessageBox::information(this, "Circle Studio", "Circular video note successfully saved into LightGram Media Vault!");
    } else {
        QMessageBox::critical(this, "Circle Studio", "Failed to save into vault.");
    }
}

} // namespace LightGram
