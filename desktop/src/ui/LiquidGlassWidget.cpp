#include "LiquidGlassWidget.hpp"
#include <QPainterPath>
#include <QLinearGradient>

namespace LightGram {

LiquidGlassWidget::LiquidGlassWidget(QWidget* parent) : QWidget(parent) {
    setAttribute(Qt::WA_TranslucentBackground);
}

void LiquidGlassWidget::paintEvent(QPaintEvent* event) {
    Q_UNUSED(event);
    QPainter p(this);
    p.setRenderHint(QPainter::Antialiasing);

    QRectF r = rect();
    r.adjust(0.5, 0.5, -0.5, -0.5);

    QPainterPath path;
    path.addRoundedRect(r, m_radius, m_radius);

    // Subtle soft glass gradient
    QColor topCol = m_glassColor;
    topCol.setAlphaF(qBound(0.0, m_opacity, 1.0));
    QColor botCol = m_glassColor;
    botCol.setAlphaF(qBound(0.0, m_opacity * 0.9, 1.0));

    QLinearGradient grad(r.topLeft(), r.bottomLeft());
    grad.setColorAt(0.0, topCol);
    grad.setColorAt(1.0, botCol);

    p.fillPath(path, grad);

    // Glass reflection stroke
    QPen pen(m_borderColor, 1.0);
    p.setPen(pen);
    p.drawPath(path);
}

} // namespace LightGram
