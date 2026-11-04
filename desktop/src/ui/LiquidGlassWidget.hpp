#pragma once

#include <QWidget>
#include <QColor>
#include <QPainter>

namespace LightGram {

class LiquidGlassWidget : public QWidget {
    Q_OBJECT
public:
    explicit LiquidGlassWidget(QWidget* parent = nullptr);

    void setGlassColor(const QColor& color) { m_glassColor = color; update(); }
    void setBorderColor(const QColor& color) { m_borderColor = color; update(); }
    void setCornerRadius(int r) { m_radius = r; update(); }
    void setOpacity(double op) { m_opacity = op; update(); }
    void setElevated(bool elevated) { m_elevated = elevated; update(); }

protected:
    void paintEvent(QPaintEvent* event) override;

private:
    QColor m_glassColor = QColor(28, 28, 30, 200);
    QColor m_borderColor = QColor(255, 255, 255, 25);
    int m_radius = 16;
    double m_opacity = 0.85;
    bool m_elevated = false;
};

} // namespace LightGram
