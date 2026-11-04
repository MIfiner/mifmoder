#pragma once

#include <QDialog>
#include <QPushButton>
#include <QLabel>
#include <QLineEdit>
#include <QSlider>

namespace LightGram {

class CircleStudioDialog : public QDialog {
    Q_OBJECT
public:
    explicit CircleStudioDialog(QWidget* parent = nullptr);

private slots:
    void onSelectVideo();
    void onTogglePlay();
    void onSaveToVault();

private:
    void setupUi();

    QLineEdit* m_videoPathEdit = nullptr;
    QWidget* m_circleViewport = nullptr;
    QPushButton* m_playBtn = nullptr;
    QSlider* m_trimSlider = nullptr;
    QLabel* m_statusLabel = nullptr;
    QString m_selectedVideoPath;
};

} // namespace LightGram
